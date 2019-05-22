defmodule Membrane.Element.IbmSpeechToText.Sink do
  use Membrane.Element.Base.Sink

  def_input_pads input: [
    caps: :any,
    demand_unit: :buffers
  ]

  @impl true
  def handle_prepared_to_playing(_context, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_demand(_pad, _size, _unit, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_write(_pad, _payload, _ctx, state) do
    {{:ok, demand: :input}, state}
  end
end
