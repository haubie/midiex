defmodule Midiex.OutConn do
  @moduledoc """
  A struct representing an open connection to a MIDI output port.

  The keys are as follows:
  - *conn_ref* the reference (e.g. `#Reference<0.2239960018.1937899544.176288>`) to the connection object in midir (Rust).
  - *name* a string containing the name of the port this connection is to
  - *port_num* a integer representing the index of the output port.

  ## Documentation from midir
  See MidiOutputConnection at: https://docs.rs/midir/latest/midir/struct.MidiOutputConnection.html

  ## Example
  ```
  # Pass a port from taken from Midiex.ports(:output)
  # e.g. port = Midiex.ports(:output) |> List.first()
  port =
    %Midiex.MidiPort{
      direction: :output,
      name: "IAC Driver Bus 1",
      num: 0,
      port_ref: #Reference<0.3876911033.1674706968.249863>
    }

  output_conn = Midiex.open(port)
  ```
  output_conn will look something like this:
  ```
   %Midiex.OutConn{
      conn_ref: #Reference<0.3876911033.1674706945.249916>,
      name: "IAC Driver Bus 1",
      port_num: 0
    }
  ```
  An output port can be closed as follows:
  ```
  Midiex.close(output_conn)
  # :ok is returned if successful
  ```
  """

  defstruct ~w/conn_ref name port_num/a
end
