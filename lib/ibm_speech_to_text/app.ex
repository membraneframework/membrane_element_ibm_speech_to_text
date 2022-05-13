defmodule Membrane.Element.IBMSpeechToText.App do
  @moduledoc false
  use Application

  @impl Application
  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
