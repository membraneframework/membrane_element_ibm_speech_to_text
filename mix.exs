defmodule Membrane.Element.IBMSpeechToText.MixProject do
  use Mix.Project

  @version "0.3.0"
  @github_url "https://github.com/membraneframework/membrane-element-ibm-speech-to-text"

  def project do
    [
      app: :membrane_element_ibm_speech_to_text,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # hex
      description: "Membrane Multimedia Framework (IBMSpeechToText Element)",
      package: package(),

      # docs
      name: "Membrane Element: IBMSpeechToText",
      source_url: @github_url,
      homepage_url: "https://membraneframework.org",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:membrane_core, "~> 0.6.0"},
      {:membrane_caps_audio_flac, "~> 0.1.1"},
      {:ibm_speech_to_text, "~> 0.3.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:membrane_element_file, "~> 0.3", only: [:dev, :test]},
      {:membrane_element_flac_parser, "~> 0.3", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.Element],
      before_closing_head_tag: &sidebar_fix/1
    ]
  end

  defp sidebar_fix(_) do
    """
    <style type="text/css">
    .sidebar div.sidebar-header {
      margin: 15px;
    }
    </style>
    """
  end
end
