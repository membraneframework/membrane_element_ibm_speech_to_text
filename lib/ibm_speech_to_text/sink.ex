defmodule Membrane.Element.IBMSpeechToText.Sink do
  use Membrane.Element.Base.Sink
  alias Membrane.Buffer
  alias Membrane.Event.{StartOfStream, EndOfStream}
  alias IBMSpeechToText.{Client, Message, Response}

  def_input_pad :input, caps: :any, demand_unit: :buffers

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
    {:ok, opts}
  end

  @impl true
  def handle_prepared_to_playing(_context, state) do
    with {:ok, pid} <- Client.start_link(state.region, state.api_key) do
      {:ok, %{connection: pid}}
    end
  end

  @impl true
  def handle_event(:input, %StartOfStream{}, _, %{connection: conn} = state) do
    Client.send_message(conn, %Message.Start{})
    {:ok, state}
  end

  @impl true
  def handle_event(:input, %EndOfStream{}, _, %{connection: conn} = state) do
    Client.send_message(conn, %Message.Stop{})
    {:ok, state}
  end

  @impl true
  def handle_write(_pad, %Buffer{payload: payload}, _ctx, %{connection: conn} = state) do
    Client.send_data(conn, payload)
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_other(%Response{} = response, _ctx, state) do
    {{:ok, notify: response}, state}
  end
end
