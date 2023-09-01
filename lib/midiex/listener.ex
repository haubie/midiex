defmodule Midiex.Listener do
  @moduledoc """
  GenServer for subscribing to MIDI input ports and responding to the MIDI messages (`Midiex.MidiMessage`) received.

  ## How this works
  This GenServer works by:
  - Subscribing to one or more MIDI input ports (using `Midiex.subscribe/1`). For each MIDI input port, `Midiex.subscribe/1` will create a new OS thread (in Rust) which establishes a connection to the port and listens to messages. Incoming messages are then forwarded to the calling Elixir process (in this case, the `Midiex.Listener` process.)

    A subscription can be established on the `start_link/1` or `subscribe/2` functions, e.g.:
    ```
    # Get the first MIDI input port
    input_port = Midiex.ports(:input) |> List.first()

    # Start a lister for this MIDI input port
    {:ok, listner} =  Midiex.Listener.start_link(port: input_port)
    ```
  - Receieves MIDI messages in the form of a `Midiex.MidiMessage` struct, and passes it onto one or more Elixir handler functions. The handler takes one parameter representing the MIDI message, e.g.:
    ```
    # Add a simple message handler which inspects each message received:
    Listener.add_handler(listener, fn (midi_msg) -> IO.inspect(midi_msg) end)
    ```

  ![Midiex](assets/how_listener_works.png)

  ## Example
  ```
  alias Midiex.Listener

  # Get the first MIDI input port
  input_port = Midiex.ports(:input) |> List.first()

  # Start a lister for this MIDI input port
  {:ok, listner} = Listener.start_link(port: input_port)

  # Create a handler than inspects the MIDI messages received:
  my_msg_hander = fn (midi_msg) -> IO.inspect(midi_msg, label: "MIDI message") end
  Listener.add_handler(listener, &my_msg_hander/1)

  # Stop listening to the input port
  Listener.unsubscribe(listner, input_port)
  ```
  """

  use GenServer

  defstruct port: [], callback: []

  @impl true
  def init(state \\ %__MODULE__{}) do
    if state.port && state.port != [], do: subscribe(self(), state.port)
    {:ok, state}
  end

  @impl true
  def handle_cast({:subscribe, midi_input_port}, state) do
    Midiex.subscribe(midi_input_port)
    midi_input_port = if is_list(midi_input_port), do: midi_input_port, else: [midi_input_port]
    new_state = %__MODULE__{state | port: midi_input_port ++ []}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:add_handler, handler_fn}, state) do
    handler_fn = if is_list(handler_fn), do: handler_fn, else: [handler_fn]
    new_state = %__MODULE__{state | callback: handler_fn ++ state.callback}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:unsubscribe, midi_input_port}, state) do
    Midiex.unsubscribe(midi_input_port)
    port = Enum.reject(state.port, fn port -> ports_equal?(port, midi_input_port) end)
    new_state = %__MODULE__{state | port: port}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:unsubscribe_all, state) do
    Midiex.unsubscribe(state.callback)
    new_state = %__MODULE__{state | callback: []}
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(info, state) do
    # IO.inspect info, label: "INFO MSG"
    state.callback
    |> Enum.each(fn callback_fn -> callback_fn.(info) end)

    {:noreply, state}
  end

  # ---
  # API
  # ---

  @doc """
  Creates a new %Midiex.Server{} struct.

  Takes an optional keyword list as the first parameter which can be used to populate individual struct keys.

  The struct holds the following key-values:
  - `:port` which holds a list of MIDI input ports to listen to. These can be device ports `%Midiex.MidiPort{direction: :input}` or virtual ports `%Midiex.VirtualMidiPort{}`
  - `:callback` which holds a list of functions called when a message is received for an input port. The callback must be of single arity and take it's first parameter a message. See `add_handler/2` for an example.
  """
  def new(opts \\ []) do
    port =
      case Keyword.get(opts, :port) do
        ports when is_list(ports) -> ports
        port when is_struct(port) -> [port]
        _ -> []
      end

    callback =
      case Keyword.get(opts, :callback) do
        callbacks when is_list(callbacks) -> callbacks
        callback when is_function(callback) -> [callback]
        _ -> []
      end

    %__MODULE__{port: port, callback: callback}
  end


  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Start the Midiex.Server GenServer.

  Takes an optional keyword list as the first parameter which can be used to populate individual %Midiex.Listener{} struct keys. See `new/1` for informaton.

  ## Examples
  ```
  # Start with no options
  {:ok, listener} = Midiex.Listener.start_link()

  # Start, already passing the first available input port to listen to
  first_port = Midiex.ports(:input) |> List.first()
  {:ok, listener} = Midiex.Listener.start_link(ports: first_port)

  # Start, already passing a list of all input ports available to listen to
  {:ok, listener} = Midiex.Listener.start_link(ports: Midiex.ports(:input))
  ```
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, new(opts))
  end

  # @doc """
  # To add an input port to listen to.
  # """
  # def listen_to(pid, input_port) do
  #   GenServer.cast(pid, {:add_input_port, input_port})
  # end

  @spec add_handler(pid(), function() | [function()]) :: :ok
  @doc """
  Add one or more callback function(s) which will recieve and handle MIDI messages.

  A single callback function or multiple callback functions can be provided in a list.

  ## Example
  ```
  # Start your Listener process
  {:ok, listener} = Listener.start_link(port: input_port)

  # Add a single handler
  Listener.add_handler(listener, fn msg -> IO.inspect msg, label: "Inspecting msg" end)

  # Add multiple handlers in a list
  Listener.add_handler(
    listener,
    [
      fn msg -> IO.inspect msg, label: "Msg handler 1" end,
      fn msg -> IO.inspect msg, label: "Msg handler 1" end,
    ]
  )

  # If you've defined your hander function in a module function, pass it the usual way:
  Listener.add_handler(listener, &MyModule.function_name/1)
  ```
  """
  def add_handler(pid, handler_fn) do
    GenServer.cast(pid, {:add_handler, handler_fn})
  end

  @spec unsubscribe(pid(), %Midiex.MidiPort{direction: :input} | %Midiex.VirtualMidiPort{} | [%Midiex.MidiPort{direction: :input} | %Midiex.VirtualMidiPort{}] | :all) :: :ok
  @doc """
  Stops listening to the MIDI input port by unsubscribing to it.

  This accepts both ports listed on your device `%Midiex.MidiPort{direction: :input}` and virtual ports `%Midiex.VirtualMidiPort{}` you've created.

  It accepts as it's second parameter either:
  - a single MIDI input port
  - a list of MIDI input ports
  - `:all` atom which will stop all MIDI input ports subscribed to.

  > #### Important {: .warning}
  >
  > This stops the Rust OS thread from sending messages from that MIDI input port. If other Elixir processes have also subscribed to that port, they will also stop recieving messages.
  >
  """
  def unsubscribe(pid, :all) do
    GenServer.cast(pid, :unsubscribe_all)
  end
  def unsubscribe(pid, midi_input_ports) when is_list(midi_input_ports) do
    Enum.each(midi_input_ports, fn midi_input_port -> unsubscribe(pid, midi_input_port) end)
  end
  def unsubscribe(pid, midi_input_port) do
    GenServer.cast(pid, {:unsubscribe, midi_input_port})
  end

  @spec subscribe(pid(), %Midiex.MidiPort{direction: :input} | %Midiex.VirtualMidiPort{} | [%Midiex.MidiPort{direction: :input} | %Midiex.VirtualMidiPort{}] ) :: :ok
  @doc """
  Subscribe to one or more MIDI input ports.

  This accepts both ports listed on your device `%Midiex.MidiPort{direction: :input}` and virtual ports `%Midiex.VirtualMidiPort{}` you've created.

  It accepts as it's second parameter either:
  - a single MIDI input port
  - a list of MIDI input ports
  - `:all` atom which will stop all MIDI input ports subscribed to.

  ## Example
  ```
  # Subscribe to the input port of the Arturia KeyStep Pro keyboard
  keystep_in_port = Midiex.port("KeyStep Pro", :input)

  # Returns a list with matching port names, in this case:
  [
    %Midiex.MidiPort{
        direction: :input,
        name: "KeyStep Pro",
        num: 2,
        port_ref: #Reference<0.3139841870.4103995416.58432>
      }
  ]

  # Create and start a listener process
  {:ok, keyboard} = Midiex.Listener.start_link()

  # Listen to MIDI messages from the keyboard
  Midiex.Listener.subscribe(keyboard, keystep_in_port)

  # Any keys you push on the keyboard will be listened to. Add one or more handlers with Midiex.Listener.add_handler/2 to process messages.
  ```
  """
  def subscribe(pid, midi_input_port) do
    GenServer.cast(pid, {:subscribe, midi_input_port})
  end

  @spec get_state(pid()) :: %Midiex.Listener{}
  @doc """
  Gets the servers state, returns `%Midiex.Listener{}` struct.
  """
  def get_state(pid) do
    GenServer.call(pid, :state)
  end

  # ----------------
  # Helper functions
  # ----------------
  defp ports_equal?(port_one, port_two), do: (port_one.name == port_two.name) && (port_one.num == port_two.num)





end
