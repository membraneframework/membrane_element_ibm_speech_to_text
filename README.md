# Membrane Multimedia Framework: IBM Speech To Text

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_element_ibm_speech_to_text.svg)](https://hex.pm/packages/membrane_element_ibm_speech_to_text)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane-element-ibm-speech-to-text.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane-element-ibm-speech-to-text)

This package provides a Sink wrapping [IBM Speech To Text Streaming API client](https://hex.pm/packages/ibm_speech_to_text).
Currently supports only audio streams in FLAC format.

The docs can be found at [HexDocs](https://hexdocs.pm/membrane_element_ibm_speech_to_text).

## Installation

The package can be installed by adding `membrane_element_ibm_speech_to_text` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_element_ibm_speech_to_text, "~> 0.1.0"}
  ]
end
```

## Usage

The input stream for this element should be parsed, so most of the time it should be
placed in pipeline right after [FLACParser](https://github.com/membraneframework/membrane-element-flac-parser)

Here's an example of pipeline streaming audio file to speech recognition API:

```elixir
defmodule SpeechRecognition do
  use Membrane.Pipeline

  alias IBMSpeechToText.Response
  alias Membrane.Element.{File, FLACParser, IBMSpeechToText}

  @impl true
  def handle_init(_) do
    children = [
      src: %File.Source{location: "sample.flac"},
      parser: FLACParser,
      sink: %IBMSpeechToText{
        region: :frankfurt,
        api_key: "PUT_YOUR_API_KEY_HERE"
      }
    ]

    links = %{
      {:src, :output} => {:parser, :input},
      {:parser, :output} => {:sink, :input}
    }

    spec = %Membrane.Pipeline.Spec{
      children: children,
      links: links
    }

    {{:ok, spec}, %{}}
  end

  @impl true
  def handle_notification(%Response{} = response, _element, state) do
    IO.inspect(response)
    {:ok, state}
  end

  def handle_notification(_notification, _element, state) do
    {:ok, state}
  end
end
```

To run, the pipeline requires following dependencies:

```elixir
[
  {:membrane_core, "~> 0.3.0"},
  {:membrane_element_file, "~> 0.2"},
  {:membrane_element_flac_parser, "~> 0.1"},
  {:membrane_element_ibm_speech_to_text, "~> 0.1"}
]
```

## Copyright and License

Copyright 2019, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-ibm-speech-to-text)

[![Software Mansion](https://membraneframework.github.io/static/logo/swm_logo_readme.png)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-ibm-speech-to-text)

Licensed under the [Apache License, Version 2.0](LICENSE)
