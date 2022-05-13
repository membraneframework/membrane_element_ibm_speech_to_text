defmodule Membrane.Element.IBMSpeechToText.MixProject do
  use Mix.Project

  @version "0.6.0"
  @github_url "https://github.com/membraneframework/membrane-element-ibm-speech-to-text"

  def project do
    [
      app: :membrane_element_ibm_speech_to_text,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),

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
      {:membrane_core, "~> 0.10.0"},
      {:membrane_caps_audio_flac, "~> 0.1.1"},
      {:ibm_speech_to_text, "~> 0.3.0"},
      {:membrane_file_plugin, "~> 0.12.0", only: [:dev, :test]},
      {:membrane_flac_plugin, "~> 0.8.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
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
      formatters: ["html"],
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
