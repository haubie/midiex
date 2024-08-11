defmodule Midiex do
  @moduledoc ~S"""
  This is the main Midiex module.

  It's built around three basic concepts:
  1. **Ports:**
    - **list** or **count** MIDI ports availble (for example, a keyboard or synth)
  2. **Connections:**
    - **open** or **close** connections to MIDI ports
    - **create a virtual input or output connections** so your Elixir application appears as a MIDI device
  3. **Messages:**
    - **send** or **receive messages** to and from connections.

  ![Grokking MIDI](assets/grokking_midi.png)

  ## Examples
  ```
  # List MIDI ports
  Midiex.ports()

  # Lists MIDI ports discoverable on your system
  # [
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "IAC Driver Bus 1",
  #     num: 0,
  #     port_ref: #Reference<0.2239960018.1937899544.176288>
  #   },
  #   %Midiex.MidiPort{
  #     direction: :output,
  #     name: "IAC Driver Bus 1",
  #     num: 0,
  #     port_ref: #Reference<0.2239960018.1937899544.176289>
  #   }
  # ]

  # Create a virtual output connection
  piano = Midiex.create_virtual_output("piano")

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

  defguardp is_output_conn(midi_conn) when is_struct(midi_conn, Midiex.OutConn)
  defguardp is_output_port(midi_port) when is_struct(midi_port, Midiex.MidiPort) and midi_port.direction == :output
  defguardp is_input_port(midi_port) when is_struct(midi_port, Midiex.MidiPort) and midi_port.direction == :input
  defguardp is_virtual_input_port(midi_port) when is_struct(midi_port, Midiex.VirtualMidiPort) and midi_port.direction == :input


  # ##########
  # NATIVE API
  # ##########

  # MIDI port functions

  @doc section: :ports
  @spec ports :: [%Midiex.MidiPort{}]
  @doc """
  Lists MIDI ports availabile on the system.

  ```
  Midiex.ports()

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
  def ports(), do: Backend.list_ports()

  @doc section: :ports
  @spec ports(:input | :output) :: [%Midiex.MidiPort{}]
  @doc """
  List MIDI ports matching the specified direction (e.g. input or output)

  Takes an atom as the first parameter representing the direction:
  - :input - lists input ports only
  - :output - lists output ports only.

  ```
  Midiex.ports(:input)

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
  def ports(direction) when is_atom(direction), do: filter_port_direction(ports(), direction)

  @doc section: :ports
  @spec ports(binary | map, (:input | :output)|nil) :: [%Midiex.MidiPort{}]
  @doc """
  Lists MIDI ports matching the name. This can be either a string match or a regex pattern.

  Optionally takes a direction (:input or :output) can be given.

  Examples:
  ```
  # Regex examples

  # List ports containing the word 'Arturia' and ignore case
  Midiex.ports(~r/Arturia/i)

  # List output ports starting the word 'Arturia' and ignore case
  Midiex.ports(~r/^Arturia/i, :output)

  # String matching examples

  # List input ports with the name 'KeyStep Pro'
  Midiex.ports("KeyStep Pro", :input)

  # List output ports with the name 'Arturia MicroFreak'
  Midiex.ports("Arturia MicroFreak", :output)
  ```
  """
  def ports(name_or_pattern, direction \\ nil) when is_binary(name_or_pattern) or is_struct(name_or_pattern) do
    filter_port_name(ports(), name_or_pattern, direction: direction)
  end

  @doc section: :ports
  @doc """
  Returns the count of the number of input and output MIDI ports in as a map.

  ```
  Midiex.port_count()

  # Returns a map in the following format:
  # %{input: 2, output: 0}
  ```
  """
  def port_count(), do: Backend.count_ports()

  @doc section: :connections
  @spec open(%Midiex.MidiPort{direction: :output} | [%Midiex.MidiPort{direction: :output}]) :: %Midiex.OutConn{} | [%Midiex.OutConn{}]
  @doc """
  Creates a connection to the MIDI port.

  Accepts one of the following as a parameter:
  - MIDI output port, e.g. a `%Midiex.MidiPort{direction: :output}` struct
  - List of MIDI output ports.

  Returns an output connection (`%Midiex.OutConn{)`) or a list of output connections if a list was output ports was given as the first parameter.

  ## Example

  ### Connect to a single output port
  ```
  # Get the first available MIDI output port
  out_port = Midiex.ports(:output) |> List.first()

  # Open an output connection
  out_conn = Midiex.open(out_port)

  # Returns an output connection struct, for example:
  %Midiex.OutConn{
    conn_ref: #Reference<0.3613027763.2067398660.163505>,
    name: "IAC Driver Bus 1",
    port_num: 0
  }
  ```
  You can now send messages to the connection:
  ```
  # Send a note on message for D4
  Midiex.msg_send(out_conn, Midiex.Message.note_on(:D4))

  # Let note play for 2 seconds
  :timer.sleep(2000)

  # Send a note off message for D4
  Midiex.msg_send(out_conn, Midiex.Message.note_off(:D4))
  ```
  ### Connect to a list of output ports
  ```
  # Get a list of available output ports
  out_ports = Midiex.ports(:output)

  # Returns a list of available MIDI output ports, e.g.:
  [
    %Midiex.MidiPort{
      direction: :output,
      name: "Arturia MicroFreak",
      num: 1,
      port_ref: #Reference<0.3139841870.4103995416.58431>
    },
    %Midiex.MidiPort{
      direction: :output,
      name: "KeyStep Pro",
      num: 2,
      port_ref: #Reference<0.3139841870.4103995416.58432>
    },
    %Midiex.MidiPort{
      direction: :output,
      name: "MiniFuse 2",
      num: 3,
      port_ref: #Reference<0.3139841870.4103995416.58433>
    }
  ]

  # Connect to each port
  out_conns = Midiex.open(out_ports)

  # Returns a list of MIDI output connections, e.g.:
  [
    %Midiex.OutConn{
      conn_ref: #Reference<0.1633267383.3718381569.210768>,
      name: "Arturia MicroFreak",
      port_num: 1
    },
    %Midiex.OutConn{
      conn_ref: #Reference<0.3139841870.4103995416.58432>,
      name: "KeyStep Pro",
      port_num: 2
    },
    %Midiex.OutConn{
      conn_ref: #Reference<0.3139841870.4103995416.58433>,
      name: "MiniFuse 2",
      port_num: 3
    }
  ]
  ```
  """
  def open([midi_output_port | rest_ports]) when is_output_port(midi_output_port) do
    ([Backend.connect(midi_output_port)] ++ open(rest_ports))
  end
  def open([]), do: []
  def open(midi_output_port) when is_output_port(midi_output_port), do: Backend.connect(midi_output_port)


  @doc section: :connections
  @spec close(%Midiex.OutConn{} | [%Midiex.OutConn{}]) :: any
  @doc """
  Closes a MIDI output connection.

  Accepts as the first parameter either a:
  - MIDI output connection, e.g. a `%Midiex.OutConn{}` struct
  - List of output connections.

  ## Example
  ```
  # Connect to the first output port
  out_port = Midiex.ports(:output) |> List.first()
  out_conn = Midiex.open(out_port)

  Midiex.close_out_conn(out_conn)
  # Will return :ok if successful
  ```
  """
  def close([out_conn | rest_conns]) do
    [Backend.close_out_conn(out_conn)] ++ close(rest_conns)
  end
  def close([]), do: []
  def close(out_conn) do
    Backend.close_out_conn(out_conn)
  end
  @doc section: :virtual
  @spec create_virtual_output(String.t()) :: %Midiex.OutConn{}
  @doc """
  Creates a virtual output connection.

  This allows your Elixir application to be seen as a MIDI device.

  Note this is only available on platforms that support virtual ports (currently every platform but Windows).

  ```
  # Create an output connection called "piano"
  piano_conn = Midiex.create_virtual_output("piano")
  ```

  You can send messages to MIDI software or hardware connected to this virtual device in the standard way, e.g.:
  ```
  note_on = <<0x90, 60, 127>>
  note_off = <<0x80, 60, 127>>

  Midiex.send_msg(piano, note_on)
  :timer.sleep(3000) # wait three seconds
  Midiex.send_msg(piano, note_off)
  ```

  > #### Important {: .warning}
  >
  > Even though this creates an output port, beacause it's a virtual port it is listed as an 'input' when querying the OS for available devices.
  >
  > That means other software or devices will discover it and use it as a an input, such as to receive messages.
  >
  > It also means it will show as `%Midiex.MidiPort{direction: :input}` when calling `Midiex.ports()`.

  """
  def create_virtual_output(name), do: Backend.create_virtual_output_conn(name)

  @doc section: :virtual
  @spec create_virtual_input(String.t()) :: %Midiex.VirtualMidiPort{}
  @doc """
  Creates a virtual input port struct.

  Takes a name as the first parameter.

  This is only available on platforms that support virtual ports (currently every platform but Windows).

  > #### Important {: .warning}
  >
  > Even though this creates an input port, beacause it's a virtual port it is listed as an 'output' when querying the OS for available devices.
  >
  > That means other software or devices will discover it and use it as a an output and can send messages to it.
  >
  > It also means it will show as `%Midiex.MidiPort{direction: :output}` when calling `Midiex.ports()`.
  >
  > Note that it won't be discoverable until the input port is subscribed.

  ## Example
  ```
  # Create a virtual MIDI input by giving it a name. MIDIex will also assign it an input port number (`num`).
  my_virtual_in = Midiex.create_virtual_input("My Virtual Input")

  # This will return a VirtualMidiPort struct in the following format
  # %Midiex.VirtualMidiPort{direction: :input, name: "My Virtual Input", num: 1}
  ```
  The `%Midiex.VirtualMidiPort{}` struct can then be passed to MIDI input port listener functions, such as:
  - `Midiex.subscribe(my_virtual_in)`
  - If using a Listener GenServer:
    - `Midiex.Listener.start_link(port: my_virtual_in)`
    - `Midiex.Listener.subscribe(listener, my_virtual_in)`

  Likewise, once subscribed to, the virtual input port can be unsubscribed to:
  - `Midiex.unsubscribe(my_virtual_in)`
  - If using a Listener GenServer: `Midiex.Listener.unsubscribe(my_virtual_in)`
  """
  def create_virtual_input(name), do: Backend.create_virtual_input(name)

  # MIDI messaging functions

  @doc section: :messages
  @spec send_msg(%Midiex.OutConn{} | [%Midiex.OutConn{}], binary) :: %Midiex.OutConn{} | [%Midiex.OutConn{}]
  @doc """
  Sends a binary MIDI message to one or more output connection(s).

  Takes the following parameters:
  1. Output connection: which is an %Midiex.OutConn{} struct or a list of Midiex.OutConn{} structs
  2. MIDI message: which is in a binary format, such as <<0x90, 60, 127>>

  Returns the same output connection or a list of output connections passed to it. This is so you can chain messages together.

  ## Example
  ### Send a message to single output connection
  ```
  # Connect to the first available MIDI output port
  out_conn = Midiex.ports(:output) |> List.first() |> Midiex.open()

  # Play the note D3 on all that connection for 3 seconds

  out_conn
  |> Midiex.send_msg(Midiex.Message.note_on(:D3))
  |> tap(fn _ -> :timer.sleep(3000) end) # wait 3 seconds
  |> Midiex.send_msg(Midiex.Message.note_off(:D3))

  ```
  ### Send the same message to ALL available outputs
  ```
  # Get a list of output ports and create connections for them
  out_conns = Midiex.ports(:output) |> Midiex.open()

  # Play the note D3 on all those connections for 3 seconds

  out_conns
  |> Midiex.send_msg(Midiex.Message.note_on(:D3))
  |> tap(fn _ -> :timer.sleep(3000) end) # wait 3 seconds
  |> Midiex.send_msg(Midiex.Message.note_off(:D3))
  ```
  """
  def send_msg([out_port_conn | rest_conn], midi_msg) when is_output_conn(out_port_conn) do
    [Backend.send_msg(out_port_conn, midi_msg)] ++ send_msg(rest_conn, midi_msg)
  end
  def send_msg([], _midi_msg), do: []
  def send_msg(out_port_conn, midi_msg) when is_output_conn(out_port_conn), do: Backend.send_msg(out_port_conn, midi_msg)


  @doc section: :messages
  # Midiex callback functions
  @doc """
  Low-level API for subscribing to one or more MIDI input ports. This includes ports created via `create_virtual_input/1`.

  The first parameter accepts either:
  - A single `%Midiex.MidiPort{direction: :input}` or `%Midiex.VirtualMidiPort{direction: :input}` struct
  - A list of `%Midiex.MidiPort{direction: :input}` or `%Midiex.VirtualMidiPort{direction: :input}` structs.

  The calling process will receive MIDI messages from the ports subscribed to. The source of the message will be differentiated by the input port, but also consider using a different calling process for different inputs if they need to be handled separately.

  ## Example
  ```
  # Get a list of MIDI input ports on the system
  midi_input_ports = Midiex.ports(:input)

  # This function will return a list of ports discovered, e.g.:
  # [
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "Arturia MicroFreak",
  #     num: 1,
  #     port_ref: #Reference<0.3704955737.2291269656.36760>
  #   },
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "KeyStep Pro",
  #     num: 2,
  #     port_ref: #Reference<0.3704955737.2291269656.36761>
  #   },
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "MiniFuse 2",
  #     num: 3,
  #     port_ref: #Reference<0.3704955737.2291269656.36762>
  #   }
  # ]

  # Subscribe to the input ports. The current process will receive MIDI messages. Returns `:ok` if successful.
  Midiex.subscribe(midi_input_ports)
  ```

  You'll need to implement message recieving in your process.

  ## Alternative: use a Listener process
  As an alterantive you can use `Midiex.Listener` GenServer which subscribes to MIDI input ports and forwards any messages received to event handlers.

  For the above example, if you wanted to inspect messages coming in on those ports, you could:
  ```
  alias Midiex.Listener

  # Start a lister for this MIDI input port
  {:ok, listner} = Listener.start_link(port: midi_input_ports)

  # Create a handler than inspects the MIDI messages received:
  Listener.add_handler(listener, fn (midi_msg) -> IO.inspect(midi_msg.data, label: "Msg received") end)

  # Any messages received will be inspected on the console, e.g.:
  # Msg received: [130, 84, 0]
  # Msg received: [146, 60, 43]
  # Msg received: [130, 60, 0]
  # Msg received: [146, 72, 34]
  # Msg received: [130, 72, 0]
  # Msg received: [146, 76, 40]
  # Msg received: [130, 76, 0]
  # Msg received: [146, 64, 47]
  # Msg received: [130, 64, 0]
  # Msg received: [146, 84, 30]
  ```
  """
  def subscribe([midi_port | rest_ports]) when is_input_port(midi_port) or is_virtual_input_port(midi_port) do
    if rest_ports != [], do: subscribe(rest_ports)
    subscribe(midi_port)
  end
  def subscribe(midi_port) when is_input_port(midi_port), do: Backend.subscribe(midi_port)
  def subscribe(midi_port) when is_virtual_input_port(midi_port), do: Backend.subscribe_virtual_input(midi_port)

  @doc section: :messages
  @doc """
  Unsubscribes from recieving MIDI messages from an input port connection.

  Messages stop as this function releases the OS thread created for listening to the input conection.

  This function takes as the first parameter _one_ of the following:
  - Port struct: A MIDI input port `%Midiex.MidiPort{direction: :input}` or `%Midiex.VirtualMidiPort{direction: :input}` struct
  - List: A list of MIDI input port `%Midiex.MidiPort{direction: :input}` or `%Midiex.VirtualMidiPort{direction: :input}` structs
  - Number: A MIDI input port number (this is the integer in the `:num` key within the `%Midiex.MidiPort{}`) (non-virtual ports only)
  - Atom: The atom `:all`, which will unsubscribe from all MIDI input ports subscribed to, including virtual ports. If you would like to unsubscribe to virtual ports or ones listed on your device by the OS only, use `unsubscribe(:all, :virtual)` or `unsubscribe(:all, :device)` instead.

  ## Example
  ```
  # Unsubscribe from all inport ports listed on your device's OS
  Midiex.unsubscribe(:all, :device)

  # Unsubscribe from all virtual ports you created
  Midiex.unsubscribe(:all, :virtual)
  ```
  """
  def unsubscribe(midi_port) when is_input_port(midi_port) do
    Backend.unsubscribe_port(midi_port)
  end
  def unsubscribe(midi_port) when is_virtual_input_port(midi_port) do
    Backend.unsubscribe_virtual_port(midi_port)
  end
  def unsubscribe([midi_port | rest_ports]) when is_input_port(midi_port) or is_virtual_input_port(midi_port) do
    if rest_ports != [], do: unsubscribe(rest_ports)
    unsubscribe(midi_port)
  end
  def unsubscribe(:all) do
    Backend.unsubscribe_all_ports()
    Backend.unsubscribe_all_virtual_ports()
  end
  def unsubscribe(index) when is_integer(index), do: Backend.unsubscribe_port_by_index(index)
  @doc section: :messages


  @doc false
  @spec unsubscribe(:all, :virtual) :: any
  def unsubscribe(:all, :virtual), do: Backend.unsubscribe_all_virtual_ports()
  @doc false
  @spec unsubscribe(:all, :device) :: any
  def unsubscribe(:all, :device), do: Backend.unsubscribe_all_ports()

  @doc section: :messages
  @doc """
  Returns a list of ports currently subscribed to using the `subscribe/1` function.

  This will include any vitual input ports currently subscribed to.

  ## Example
  ```
  Midiex.subscribed_ports()

  # Returns of list of subscribed ports, including virtual ports, e.g.:
  [
    %Midiex.MidiPort{
      direction: :input,
      name: "IAC Driver Bus 1",
      num: 0,
      port_ref: #Reference<0.3977715800.1277296664.256043>
    },
    %Midiex.VirtualMidiPort{direction: :input, name: "My Virtual Input", num: 1}
  ]

  ```
  """
  @spec subscribed_ports :: []
  def subscribed_ports(), do: Backend.get_subscribed_ports() ++ Backend.get_subscribed_virtual_ports()

  @doc section: :notifications
  @doc """
  Low-level API for subscribing to MIDI notification messages.

  Currently only MacOS is supported.

  The calling process will receive MIDI notification messages.

  Instead of this function, consider using the `Midiex.Notifier` GenServer, which will listen to notifications and allow you to create handlers to respond to them.

  > #### Important {: .warning}
  >
  > To make sure hotplug support works on `Midiex.ports()` and `Midiex.port_count()`, make sure this function is called first. It only needs to be called once to enable hotmode support mode for the rest of your application's session.
  >
  > If you want hotplug support but don't need to receive and respond to MIDI notifications, see `hotplug/0` instead.
  >
  """
  def notifications(), do: Backend.notifications()

  @doc section: :notifications
  @doc """
  Ensures that hot-plugging of devices is supported on MacOS.

  By default on MacOS, Midiex port based functions, such as `Midiex.ports()` will only list ports visible when the Elixir app was first started. That means devices added or removed afterwards will not be reflected in `Midiex.ports()`.

  > #### Important {: .warning}
  >
  > If you'd like functions like `Midiex.ports()` to reflect the current available ports on your system, such as when plugging or unplugging physical devices, **you will need to call the `hotplug/0` function *before* `Midiex.ports` or `Midiex.port_count`**.
  >
  > You will only need to call `hotplug/0` once to enable this mode for the rest of your application's session.
  >

  This function is similar to the `notifications/0` function, expect the calling Elixir process will not receive any MIDI notification messages.

  If you need to respond to MIDI notification messages, use `notifications/0` instead of this function (or use the `Midiex.Notifier` GenServer) and make sure it has been called before `Midiex.ports` or `Midiex.port_count` so hot-plugging is supported.
  """
  def hotplug(), do: Backend.hotplug()

  # #######
  # HELPERS
  # #######

  defp filter_port_name(ports_list, comparison_name_or_pattern, opts) do
    direction = Keyword.get(opts, :direction, nil)
    ports_list
    |> Enum.filter(fn port -> port_name_matches?(port.name, comparison_name_or_pattern) end)
    |> filter_port_direction(direction)
  end

  defp port_name_matches?(port_name, comparison_name_or_pattern) when is_binary(comparison_name_or_pattern) do
    String.equivalent?(port_name, comparison_name_or_pattern)
  end

  defp port_name_matches?(port_name, comparison_name_or_pattern) when is_struct(comparison_name_or_pattern) do
    String.match?(port_name, comparison_name_or_pattern)
  end

  defp filter_port_direction(ports_list, nil), do: ports_list

  defp filter_port_direction(ports_list, direction) do
    ports_list
    |> Enum.filter(fn port -> port.direction == direction end)
  end

end
