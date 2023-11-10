# Membrane Multimedia Framework: IBM Speech To Text

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_element_ibm_speech_to_text.svg)](https://hex.pm/packages/membrane_element_ibm_speech_to_text)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_element_ibm_speech_to_text/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_element_ibm_speech_to_text.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_element_ibm_speech_to_text)

This package provides a Sink wrapping [IBM Speech To Text Streaming API client](https://hex.pm/packages/ibm_speech_to_text).
Currently supports only audio streams in FLAC format.

The docs can be found at [HexDocs](https://hexdocs.pm/membrane_element_ibm_speech_to_text).

## Installation

The package can be installed by adding `membrane_element_ibm_speech_to_text` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_element_ibm_speech_to_text, "~> 0.9.0"}
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
  alias Membrane.{File, IBMSpeechToText}
  alias Membrane.FLAC.Parser

  @impl true
  def handle_init(_ctx, _opts) do
    structure = 
      child(:src, %File.Source{location: "sample.flac"})
      |> child(:parser, Parser)
      |> child(:sink, %IBMSpeechToText{
        region: :frankfurt,
        api_key: "PUT_YOUR_API_KEY_HERE"
      })
    

    {[spec: structure, playback: :playing], nil}
  end

  @impl true
  def handle_child_notification(%Response{} = response, _element, _ctx, state) do
    IO.inspect(response)
    {[], state}
  end

  def handle_child_notification(_notification, _element, _ctx, state) do
    {[], state}
  end
end
```

To run, the pipeline requires following dependencies:

```elixir
[
  {:membrane_core, "~> 1.0"},
  {:membrane_file_plugin, "~> 0.16.0"},
  {:membrane_flac_plugin, "~> 0.11.0"},
  {:membrane_element_ibm_speech_to_text, "~> 0.9.0"}
]
```

## Testing

The tests contacting real IBM API are excluded by default. You can run them using `mix test --include external`.
To make it work, you need to provide api key via `config/config.exs` or `config/test.secret.exs` the file needs to look like this:

```elixir
use Mix.Config

config :ibm_speech_to_text, region: :your_region # e.g. :frankfurt
config :ibm_speech_to_text, api_key: "YOUR_API_KEY_HERE"
```

## Copyright and License

Copyright 2019, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-ibm-speech-to-text)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-ibm-speech-to-text)
ipeline
Licensed under the [Apache License, Version 2.0](LICENSE)
