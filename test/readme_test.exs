defmodule ReadmeTest do
  use ExUnit.Case, async: true

  test "version in readme matches mix.exs" do
    readme_markdown = File.read!(Path.join(__DIR__, "../README.md"))
    mix_config = Mix.Project.config()
    version = mix_config[:version]
    assert readme_markdown =~ ~s({:midiex, "~> #{version}"})
  end

  # test "version in livebook/midiex_notebook.livemd matches mix.exs" do
  #   readme_markdown = File.read!(Path.join(__DIR__, "../livebook/midiex_notebook.livemd"))
  #   mix_config = Mix.Project.config()
  #   version = mix_config[:version]
  #   assert readme_markdown =~ ~s({:midiex, "~> #{version}"})
  # end

end
