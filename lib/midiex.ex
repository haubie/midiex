defmodule Midiex do
  @moduledoc """
  This is the main Midiex module.

  With this module you can:
  - Ports:
    -- **list** or **count** MIDI ports availble (for example, a keyboard or synth)
  - Connections:
    -- **create** connects to MIDI ports or **close connections**
    -- **create a virtual output connection** so your Elixir application appears as a MIDI device
  - Messages: **send** or **recieve messages** to and from connections.

  ## Examples
  ```
  # List MIDI ports
  Midiex.list_ports()

  # Create a virtual output connection
  piano = Midiex.create_virtual_output_conn("piano")

  # Returns an output connection:
  # %Midiex.OutConn{
  #   conn_ref: #Reference<0.1633267383.3718381569.210768>,
  #   name: "piano",
  #   port_num: 0
  # }

  # Send MIDI messages to a connection
  # In the message below, the note 60 is equivalent to Middle C and 127 means maximum velocity
  note_on = <<0x90, 60, 127>>
  note_off = <<0x80, 60, 127>>

  Midiex.send_msg(piano, note_on)
  :timer.sleep(3000) # wait three seconds
  Midiex.send_msg(piano, note_off)
  ```
  ### Livebook tour
  Also see the introductory tour in LiveBook at [/livebook/midiex_notebook.livemd](https://github.com/haubie/midiex/blob/main/livebook/midiex_notebook.livemd).

  [![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fhaubie%2Fmidiex%2Fblob%2Fmain%2Flivebook%2Fmidiex_notebook.livemd)
  """
  alias Midiex.Backend

  # ##########
  # NATIVE API
  # ##########

  # MIDI port functions

  @doc section: :ports
  @doc """
  Lists MIDI ports availabile on the system.

  ```
  Midiex.list_ports()

  # Returns a list of input or output ports:

  # [
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "Piano",
  #     num: 0,
  #     port_ref: #Reference<0.249304305.242352152.40090>
  #   },
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "Drums",
  #     num: 1,
  #     port_ref: #Reference<0.249304305.242352152.40091>
  #   }
  # ]
  ```
  """
  def list_ports(), do: Backend.list_ports()

  @doc section: :ports
  @doc """
  List MIDI ports matching the specified direction (e.g. input or output)

  Takes an atom as the first parameter representing the direction:
  - :input - lists input ports only
  - :output - lists output ports only.

  ```
  Midiex.list_ports(:input)

  # Returns a list of input or output MIDI ports:

  # [
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "Piano",
  #     num: 0,
  #     port_ref: #Reference<0.249304305.242352152.40090>
  #   },
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "Drums",
  #     num: 1,
  #     port_ref: #Reference<0.249304305.242352152.40091>
  #   }
  # ]
  ```
  """
  def list_ports(direction) when is_atom(direction), do: filter_port_direction(list_ports(), direction)

  @doc section: :ports
  @doc """
  Lists MIDI ports containing the name. Optionally takes a direction (:input or :output) can be given.

  Examples:
  ```
  # List ports with the name 'Arturia'
  Midiex.list_ports("Arturia")

  # List input ports with the name 'Arturia'
  Midiex.list_ports("Arturia", :input)

  # List output ports with the name 'Arturia'
  Midiex.list_ports("Arturia", :output)
  ```
  """
  def list_ports(name, direction \\ nil) when is_binary(name) do
    filter_port_name_contains(list_ports(), name, direction: direction)
  end

  @doc section: :ports
  @doc """
  Returns the count of the number of input and output MIDI ports in as a map.

  ```
  Midiex.count_ports()

  # Returns a map in the following format:
  # %{input: 2, output: 0}
  ```
  """
  def count_ports(), do: Backend.count_ports()

  @doc section: :connections
  @doc """
  Creates a connection to the MIDI port.

  ```
  # get the first available output port
  out_port = Midiex.list_ports(:output) |> List.first()
  out_conn = Midiex.connect(out_port)
  ```
  """
  def open(midi_port), do: Backend.connect(midi_port)

  @doc section: :connections
  @doc """
  Closes a MIDI output connection.

  ```
  Midiex.close_out_conn(out_conn)
  ```
  """
  def close(out_conn), do: Backend.close_out_conn(out_conn)

  @doc section: :connections
  @doc """
  Creates a virtual output connection.

  This allows your Elixir application to be seen as a MIDI device.

  ```
  # Create an output connection called "piano"
  piano_conn = Midiex.create_virtual_output_conn("piano")
  ```

  You can send messages to MIDI software or hardware connected to this virtual device in the standard way, e.g.:
  ```
  note_on = <<0x90, 60, 127>>
  note_off = <<0x80, 60, 127>>

  Midiex.send_msg(piano, note_on)
  :timer.sleep(3000) # wait three seconds
  Midiex.send_msg(piano, note_off)
  ```
  """
  def create_virtual_outputn(name), do: Backend.create_virtual_output_conn(name)

  # MIDI messaging functions

  @doc section: :messages
  @doc """
  Sends a binary MIDI message to a specified output connection.

  Takes the following parameters:
  - Output connection: which is an %Midiex.OutConn{} struct
  - MIDI message: which is in a binary format, such as <<0x90, 60, 127>>
  """
  def send_msg(out_port_conn, midi_msg), do: Backend.send_msg(out_port_conn, midi_msg)

  @doc section: :messages
  # Midiex callback functions
  def subscribe(), do: Backend.subscribe()
  @doc section: :messages
  def listen(input_port), do: Backend.listen(input_port)

  # #######
  # HELPERS
  # #######

  defp filter_port_name_contains(ports_list, name, opts \\ []) do
    direction = Keyword.get(opts, :direction, nil)
    ports_list
    |> Enum.filter(fn port -> String.contains?(port.name, name) end)
    |> filter_port_direction(direction)
  end

  defp filter_port_direction(ports_list, nil), do: ports_list

  defp filter_port_direction(ports_list, direction) do
    ports_list
    |> Enum.filter(fn port -> port.direction == direction end)
  end

end
