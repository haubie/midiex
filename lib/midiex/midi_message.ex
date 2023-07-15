defmodule Midiex.MidiMessage do
  @moduledoc """
  A struct representing MIDI messages recieved from MIDI inputs.

  These are recieved via the `Midiex.subscribe()` function or from the `Midiex.Listener` GenServer.

  The keys are as follows:
  - `port:` which is the input port (`%Midiex.MidiPort{}`) that sent the message
  - `data:` the MIDI message data, usually in the form of a three item list, e.g. [153, 60, 70]
  - `timestamp:` from the [midir docs](https://docs.rs/midir/latest/midir/struct.MidiInput.html#method.connect): "a timestamp (in microseconds) designating the time since some unspecified point in the past (which will not change during the lifetime of an input connection)".

  ## Example messages
  ```
  %Midiex.MidiMessage{
    port: %Midiex.MidiPort{
      direction: :input,
      name: "KeyStep Pro",
      num: 2,
      port_ref: #Reference<0.2327272197.1194197016.109029>
    },
    data: [153, 60, 70],
    timestamp: 283146647865
  }

  %Midiex.MidiMessage{
    port: %Midiex.MidiPort{
      direction: :input,
      name: "Arturia MicroFreak",
      num: 1,
      port_ref: #Reference<0.2327272197.1194197016.109028>
    },
    data: [128, 53, 33],
    timestamp: 283145644340
  }

  %Midiex.MidiMessage{
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
  ## Other examples
  See `Midiex.Listener` for examples of subscribing to MIDI messages and adding your own callback functions to process them.
  """

  defstruct ~w/port data timestamp/a


end
