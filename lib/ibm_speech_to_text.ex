defmodule Membrane.Element.IBMSpeechToText do
  @moduledoc """
  An element providing speech recognition via IBM Cloud Speech to Text service.

  This element sends speech recognition results (`t:IBMSpeechToText.Response.t()`)
  via notification mechanism to pipeline.

  It uses [ibm_speech_to_text](https://github.com/SoftwareMansion/elixir-ibm-speech-to-text)
  client library.
  """
  use Membrane.Element.Base.Sink
  use Membrane.Log, tags: :membrane_element_ibm_stt
  alias Membrane.Buffer
  alias Membrane.Caps.Audio.FLAC
  alias Membrane.Event.EndOfStream
  alias Membrane.Time
  alias IBMSpeechToText.{Client, Message, Response}

  def_input_pad :input, caps: FLAC, demand_unit: :buffers

  def_options region: [
                description: """
                Region in which the endpoint is located.
                See `t:IBMSpeechToText.region/0`
                """,
                type: :atom,
                spec: IBMSpeechToText.region()
              ],
              api_key: [
                description: """
                API key for the Speech to Text Service
                """,
                type: :string
              ],
              recognition_options: [
                description: """
                Options passed via `IBMSpeechToText.Message.Start` struct
                to recognition API affecting the results.
                See the docs for `t:IBMSpeechToText.Message.Start.t/0`
                and [IBM API docs](https://cloud.ibm.com/apidocs/speech-to-text#wstextmessages)
                """,
                type: :keyword,
                default: [interim_results: true]
              ]

  @impl true
  def handle_init(opts) do
    state =
      opts
      |> Map.from_struct()
      |> Map.merge(%{
        start_time: nil,
        samples: 0,
        sample_rate: 16_000,
        connection: nil
      })
      |> Map.update!(:recognition_options, fn rec_opts ->
        Keyword.merge(rec_opts, content_type: :flac, inactivity_timeout: -1)
      end)

    {:ok, state}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    with {:ok, pid} <- Client.start_link(state.region, state.api_key) do
      info("IBM API Client started")
      {{:ok, demand: :input}, %{state | connection: pid}}
    end
  end

  @impl true
  def handle_caps(:input, %FLAC{} = caps, _ctx, %{connection: conn} = state) do
    info("Starting recognition")
    message = struct!(Message.Start, state.recognition_options)
    Client.send_message(conn, message)
    start_time = Time.os_time()
    state = %{state | start_time: start_time, sample_rate: caps.sample_rate}
    {:ok, state}
  end

  @impl true
  def handle_event(:input, %EndOfStream{}, ctx, %{connection: conn} = state) do
    Client.send_message(conn, %Message.Stop{})
    info("End of Stream")
    super(:input, %EndOfStream{}, ctx, state)
  end

  @impl true
  def handle_event(pad, event, ctx, state) do
    super(pad, event, ctx, state)
  end

  @impl true
  def handle_write(
        :input,
        %Buffer{payload: payload, metadata: %FLAC.FrameMetadata{} = meta},
        _ctx,
        %{connection: conn, sample_rate: sample_rate, start_time: start_time} = state
      ) do
    Client.send_data(conn, payload)

    next_sample_num = meta.starting_sample_number + meta.samples
    next_frame_time = start_time + trunc(next_sample_num * Time.seconds(1) / sample_rate)
    demand_time = (next_frame_time - Time.os_time()) |> max(0) |> Time.to_milliseconds()
    Process.send_after(self(), :demand_frame, demand_time)

    {:ok, state}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, %{connection: conn} = state) do
    Client.send_data(conn, payload)
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_other(%Response{} = response, _ctx, state) do
    {{:ok, notify: response}, state}
  end

  @impl true
  def handle_other(:demand_frame, _ctx, state) do
    {{:ok, demand: :input}, state}
  end
end
