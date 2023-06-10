defmodule Midiex.MixProject do
  use Mix.Project

  def project do
    [
      app: :midiex,
      name: "Midiex",
      description: "A cross-platform, realtime MIDI processing in Elixir library which wraps the midir Rust library.",
      version: "0.1.0",
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
          "livebook/midiex_notebook.livemd",
          {:"LICENSE", [title: "License (MIT)"]},
        ],
        groups_for_modules: [
          Main: [
            Midiex,
            Midiex.Message
          ],
          Resources: [
            Midiex.MidiInputConnection,
            Midiex.MidiIO,
            Midiex.MidiOutput,
            Midiex.OutConn,
            Midiex.MidiPort
          ],
          Backend: [
            Midiex.Backend
          ]
        ],
        groups_for_docs: [
          "Ports": &(&1[:section] == :ports),
          "Connections": &(&1[:section] == :connections),
          "Messages": &(&1[:section] == :messages),
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
      {:rustler, "~> 0.26.0"},
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
        "LICENSE"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/haubie/midiex",
        "midir" => "https://github.com/Boddlnagg/midir"
        },
      maintainers: ["David Haubenschild"]
    ]
  end

end
