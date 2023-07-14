defmodule Midiex.MidiMessage do
  @moduledoc """
  A struct representing MIDI messages.

  These are recieved via the `Midiex.subscribe()` function or from the `Midiex.Listener` GenServer

  ## Example messages
  ```
  %Midiex.Message{
    port: %Midiex.MidiPort{
      direction: :input,
      name: "KeyStep Pro",
      num: 2,
      port_ref: #Reference<0.2327272197.1194197016.109029>
    },
    data: [153, 60, 70],
    timestamp: 283146647865
  }

  %Midiex.Message{
    port: %Midiex.MidiPort{
      direction: :input,
      name: "Arturia MicroFreak",
      num: 1,
      port_ref: #Reference<0.2327272197.1194197016.109028>
    },
    data: [128, 53, 33],
    timestamp: 283145644340
  }

  %Midiex.Message{
    port: %Midiex.MidiPort{
      direction: :input,
      name: "Arturia DrumBrute Impact",
      num: 0,
      port_ref: #Reference<0.2327272197.1194197016.109027>
    },
    data: [153, 36, 4],
    timestamp: 283147540161
  }
  ```
  """

  defstruct ~w/port data timestamp/a


end
