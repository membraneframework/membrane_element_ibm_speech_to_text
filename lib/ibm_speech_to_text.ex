defmodule Membrane.Element.IBMSpeechToText do
  use Membrane.Element.Base.Sink
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

    {:ok, state}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    with {:ok, pid} <- Client.start_link(state.region, state.api_key) do
      {{:ok, demand: :input}, %{state | connection: pid}}
    end
  end

  @impl true
  def handle_caps(:input, %FLAC{} = caps, _ctx, %{connection: conn} = state) do
    Client.send_message(conn, %Message.Start{content_type: :flac, interim_results: true})
    start_time = Time.os_time()
    state = %{state | start_time: start_time, sample_rate: caps.sample_rate}
    {:ok, state}
  end

  @impl true
  def handle_event(:input, %EndOfStream{}, _ctx, %{connection: conn} = state) do
    Client.send_message(conn, %Message.Stop{})
    {:ok, state}
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
    transcipts =
      response.results
      |> Enum.filter(fn result -> result.final end)
      |> Enum.map(fn result ->
        alternative = result.alternatives |> hd()
        alternative.transcript
      end)

    case transcipts do
      [] -> {:ok, state}
      _ -> {{:ok, notify: transcipts}, state}
    end
  end

  @impl true
  def handle_other(:demand_frame, _ctx, state) do
    {{:ok, demand: :input}, state}
  end
end
