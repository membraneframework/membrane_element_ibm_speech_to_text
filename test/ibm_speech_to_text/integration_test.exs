defmodule Membrane.Element.GCloud.SpeechToText.IntegrationTest do
  use ExUnit.Case

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions

  alias IBMSpeechToText.{RecognitionAlternative, RecognitionResult, Response}
  alias Membrane.FLAC.Parser
  alias Membrane.{IBMSpeechToText, Testing}

  @moduletag :external

  @fixture_path "../fixtures/sample.flac" |> Path.expand(__DIR__)

  test "recognition pipeline provides transcription of short file" do
    structure = [
      child(:src, %Membrane.File.Source{location: @fixture_path})
      |> child(:parser, Parser)
      |> child(:sink, %IBMSpeechToText{
        region: Application.get_env(:ibm_speech_to_text, :region, :frankfurt),
        api_key: Application.get_env(:ibm_speech_to_text, :api_key),
        recognition_options: [interim_results: false]
      })
    ]

    assert {:ok, _supervisor, pid} = Testing.Pipeline.start_link(structure: structure)

    assert_end_of_stream(pid, :sink, :input, 10_000)

    assert_pipeline_notified(pid, :sink, %Response{} = response, 10_000)

    assert response.result_index == 0
    assert [%RecognitionResult{alternatives: [alternative]}] = response.results
    assert %RecognitionAlternative{} = alternative

    assert alternative.transcript =~
             "adventure one a scandal in Bohemia from the adventures of Sherlock Holmes by Sir Arthur Conan Doyle"
  end
end
