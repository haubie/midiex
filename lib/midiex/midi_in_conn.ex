defmodule Midiex.InConn do
  @moduledoc """
  A struct representing an open connection to a MIDI input port.

  The keys are as follows:
  - *conn_ref* the reference (e.g. `#Reference<0.2239960018.1937899544.176288>`) to the connection object in midir (Rust).
  - *name* a string containing the name of the port this connection is to
  - *port_num* a integer representing the index of the output port.

  ## Documentation from midir
  See MidiOutputConnection at: https://docs.rs/midir/latest/midir/struct.MidiInputConnection.html

  ## Example
  ```
  # Create a virtual input
  Midiex.create_virtual_input "my-virtual-input"

  # Returns an InConn
  # %Midiex.InConn{
  #  conn_ref: #Reference<0.4008674838.2301493249.149359>,
  #  name: "my-virtual-input",
  #  port_num: 1
  # }

  ```
  """

  defstruct ~w/conn_ref name port_num/a
end
