defmodule Membrane.IBMSpeechToText do
  @moduledoc """
  An element providing speech recognition via IBM Cloud Speech to Text service.

  This element sends speech recognition results (`t:IBMSpeechToText.Response.t()`)
  via notification mechanism to pipeline.

  It uses [ibm_speech_to_text](https://github.com/SoftwareMansion/elixir-ibm-speech-to-text)
  client library.
  """
  use Membrane.Sink
  require Membrane.Logger
  alias Membrane.Caps.Audio.FLAC
  alias IBMSpeechToText.{Client, Message, Response}
  alias Membrane.{Buffer, Time, UtilitySupervisor}

  def_input_pad :input, accepted_format: FLAC, demand_unit: :buffers, flow_control: :manual

  def_options region: [
                description: """
                Region in which the endpoint is located.
                See `t:IBMSpeechToText.region/0`
                """,
                spec: IBMSpeechToText.region()
              ],
              api_key: [
                description: """
                API key for the Speech to Text Service
                """,
                spec: String.t()
              ],
              client_options: [
                description: """
                Sets the options for `IBMSpeechToText.Client.start_link/3`.
                """,
                spec: keyword(),
                default: [keep_alive: true]
              ],
              recognition_options: [
                description: """
                Options passed via `IBMSpeechToText.Message.Start` struct
                to recognition API affecting the results.
                See the docs for `t:IBMSpeechToText.Message.Start.t/0`
                and [IBM API docs](https://cloud.ibm.com/apidocs/speech-to-text#wstextmessages)
                """,
                spec: keyword(),
                default: [interim_results: true]
              ]

  @impl true
  def handle_init(_ctx, opts) do
    state =
      opts
      |> Map.from_struct()
      |> Map.merge(%{
        start_time: nil,
        timer: nil,
        samples: 0,
        sample_rate: 16_000,
        connection: nil
      })
      |> Map.update!(:recognition_options, fn rec_opts ->
        Keyword.merge(rec_opts, content_type: :flac, inactivity_timeout: -1)
      end)

    {[], state}
  end

  @impl true
  def handle_playing(ctx, state) do
    client = %{
      id: Client,
      start: {Client, :start_link, [state.region, state.api_key, state.client_options]}
    }

    with {:ok, pid} <- UtilitySupervisor.start_link_child(ctx.utility_supervisor, client) do
      Membrane.Logger.info("IBM API Client started")
      {[demand: :input], %{state | connection: pid}}
    else
      {:error, reason} -> raise "Failed to start IBM API Client, reason: #{inspect(reason)}"
    end
  end

  @impl true
  def handle_stream_format(:input, %FLAC{} = stream_format, _ctx, %{connection: conn} = state) do
    Membrane.Logger.info("Starting recognition")
    message = struct!(Message.Start, state.recognition_options)
    Client.send_message(conn, message)
    start_time = Time.os_time()
    state = %{state | start_time: start_time, sample_rate: stream_format.sample_rate}
    {[], state}
  end

  @impl true
  def handle_end_of_stream(:input, ctx, %{connection: conn} = state) do
    Client.send_message(conn, %Message.Stop{})
    Membrane.Logger.info("End of Stream")

    if state.timer != nil do
      Process.cancel_timer(state.timer)
    end

    super(:input, ctx, %{state | timer: nil})
  end

  @impl true
  def handle_buffer(
        :input,
        %Buffer{payload: payload, metadata: %FLAC.FrameMetadata{} = meta},
        _ctx,
        %{connection: conn, sample_rate: sample_rate, start_time: start_time} = state
      ) do
    Client.send_data(conn, payload)

    next_sample_num = meta.starting_sample_number + meta.samples
    next_frame_time = start_time + trunc(next_sample_num * Time.seconds(1) / sample_rate)
    demand_time = (next_frame_time - Time.os_time()) |> max(0) |> Time.as_milliseconds(:round)
    timer = Process.send_after(self(), :demand_frame, demand_time)

    {[], %{state | timer: timer}}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: payload}, _ctx, %{connection: conn} = state) do
    Client.send_data(conn, payload)
    {[demand: :input], state}
  end

  @impl true
  def handle_info(%Response{} = response, _ctx, state) do
    {[notify_parent: response], state}
  end

  @impl true
  def handle_info(:demand_frame, ctx, state) do
    if ctx.playback == :playing do
      {[demand: :input], state}
    else
      {[], state}
    end
  end
end
