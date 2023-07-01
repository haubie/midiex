defmodule Midiex.MidiPort do
  @moduledoc """
  A struct representing a MIDI port.

  The keys are as follows:
  - *direction* which is an atom of value `:input` or `:output` (for input or output port)
  - *name* which is a string the backend reported as the name of the port. With MIDI hardware, this is often the name of the device.
  - *num* an integer index representing the port starting at 0. Both input and output ports will start with 0.
  - *port_ref* a reference (e.g. `#Reference<0.2239960018.1937899544.176288>`) to the port object in midir (Rust).

  ## Notes from midir
  How a port is identified internally is backend-dependent. If the backend allows it, port objects remain valid when other ports in the system change (i.e. it is not just an index).

  -  MidiInputPort: https://docs.rs/midir/latest/midir/struct.MidiInputPort.html
  -  MidiOutputPort: https://docs.rs/midir/latest/midir/struct.MidiInputPort.html

  ## Example

  ```
  Midiex.ports()

  ```
  This will return MIDI ports available on your system, for example:

  ```
  [
    %Midiex.MidiPort{
      direction: :input,
      name: "IAC Driver Bus 1",
      num: 0,
      port_ref: #Reference<0.2239960018.1937899544.176288>
    },
    %Midiex.MidiPort{
      direction: :output,
      name: "IAC Driver Bus 1",
      num: 0,
      port_ref: #Reference<0.2239960018.1937899544.176289>
    }
  ]
  ```

  """

  defstruct ~w/direction name num port_ref/a

end
