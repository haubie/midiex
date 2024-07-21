defmodule Midiex.MixProject do
  use Mix.Project

  @version "0.6.2"
  @dev? String.ends_with?(@version, "-dev")
  @force_build? System.get_env("MIDIEX_BUILD") in ["1", "true"]

  def project do
    [
      app: :midiex,
      name: "Midiex",
      description: "A cross-platform, realtime MIDI processing in Elixir library which wraps the midir Rust library.",
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "readme",
        source_url: "https://github.com/haubie/midiex",
        homepage_url: "https://github.com/haubie/midiex",
        logo: "logo-hexdoc.png",
        assets: "assets",
        extras: [
          "README.md",
          "BUILDING.md",
          "livebook/midiex_notebook.livemd",
          {:"LICENSE", [title: "License (MIT)"]},
        ],
        groups_for_modules: [
          Main: [
            Midiex,
            Midiex.Message,
            Midiex.Listener,
            Midiex.Notifier
          ],
          "Structs and Resources": [
            Midiex.MidiIO,
            Midiex.MidiOutput,
            Midiex.OutConn,
            Midiex.MidiPort,
            Midiex.VirtualMidiPort,
            Midiex.MidiNotification,
            Midiex.MidiMessage,
          ],
          Backend: [
            Midiex.Backend
          ]
        ],
        groups_for_docs: [
          "Port discovery": &(&1[:section] == :ports),
          "Output connections": &(&1[:section] == :connections),
          "Virtual ports & connections": &(&1[:section] == :virtual),
          "Send & receive messages": &(&1[:section] == :messages),
          "Notifications & hot-plugging": &(&1[:section] == :notifications),
          "Channel voice messages": &(&1[:section] == :channel_voice),
          "Channel change messages": &(&1[:section] == :control_change),
          "Channel mode messages": &(&1[:section] == :channel_mode),
          "System messages": &(&1[:section] == :system),
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler_precompiled, "~> 0.7"},
      {:rustler, "~> 0.34.0", optional: not (@dev? or @force_build?)},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      files: [
        "lib",
        "native",
        "mix.exs",
        "README.md",
        "BUILDING.md",
        "LICENSE",
        "checksum-*.exs"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/haubie/midiex",
        "midir" => "https://github.com/Boddlnagg/midir",
        "coremidi" => "https://github.com/chris-zen/coremidi"
        },
      maintainers: ["David Haubenschild"]
    ]
  end

end
