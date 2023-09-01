defmodule Midiex.VirtualMidiPort do
  @moduledoc """
  A struct representing a virtual MIDI port.

  Currently this is only used for `:input` ports. When a viritual output port is created a `Midiex.OutConn` struct is returned instead.

  Note that viritual ports are only available on platforms that them (currently every platform but Windows).

  The keys of the struct are as follows:
  - *direction* which is an atom currently of value `:input`
  - *name* which is a string containing the name of the port
  - *num* the port number

  ## Example
  #### Virtual input port
  ```
  # Create a virtual MIDI input by giving it a name. MIDIex will also assign it an input port number (`num`).
  my_virtual_in = Midiex.create_virtual_input("My Virtual Input")

  # This will return a VirtualMidiPort struct in the following format
  # %Midiex.VirtualMidiPort{direction: :input, name: "My Virtual Input", num: 1}
  ```

  ## More information
  To create a virtual input port see `Midiex.create_virtual_input/1`
  """

  defstruct ~w/direction name num/a

end
