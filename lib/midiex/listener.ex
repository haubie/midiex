defmodule Midiex.Listener do
  @moduledoc """
  GenServer for subscribing and responding to MIDI input ports.

  This GenServer works by:
  - Subscribing to one or more MIDI input ports (using `Midiex.subscribe/1`). For each MIDI input port, `Midiex.subscribe/1` will create a new OS thread (in Rust) which establishes a connection to the port and listens to messages. Incoming messages are then forwarded to the calling Elixir process (in this case, the `Midiex.Listener` process.)

    A subscription can be established on the `start/1` or `subscribe/1` functions, e.g.:
    ```
    # Get the first MIDI input port
    input_port = Midiex.ports(:input) |> List.first()

    # Start a lister for this MIDI input port
    {:ok, listner} =  Midiex.Listener.start(port: input_port)
    ```
  - Receieves MIDI messages and passes it onto one or more Elixir handler functions. The handler takes one parameter representing the MIDI message, e.g.:
    ```
    # Add a simple message handler which inspects each message recieved:
    Listener.add_handler(listener, fn (midi_msg) -> IO.inspect(midi_msg) end)
    ```

  ## Example
  ```
  alias Midiex.Listener

  # Get the first MIDI input port
  input_port = Midiex.ports(:input) |> List.first()

  # Start a lister for this MIDI input port
  {:ok, listner} = Listener.start(port: input_port)

  # Create a handler than inspects the MIDI messages recieved:
  my_msg_hander = fn (midi_msg) -> IO.inspect(midi_msg, label: "MIDI message") end
  Listener.add_handler(listener, &my_msg_hander/1)
  ```
  """

  use GenServer

  defstruct port: [], callback: []

  @impl true
  def init(state \\ %__MODULE__{}) do
    if state.port, do: subscribe(self(), state.port)
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
    IO.inspect info, label: "INFO MSG"
    # state = check_and_action_midi_msgs(state)
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
  `listener_callback_fns` which holds a list of functions called when a message is recieved for an input port.
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




  @spec start(keyword) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Start the Midiex.Server GenServer.

  Takes an optional keyword list as the first parameter which can be used to populate individual %Midiex.Listener{} struct keys. See `new/1` for informaton.
  """
  def start(opts \\ []) do
    GenServer.start_link(__MODULE__, new(opts))
  end

  # @doc """
  # To add an input port to listen to.
  # """
  # def listen_to(pid, input_port) do
  #   GenServer.cast(pid, {:add_input_port, input_port})
  # end

  @doc """
  Add a callback function which will be called for an inport port.

  A single callback function or multiple callback functions can be provided in a list.

  ## Example
  ```
  # Start your Listener process
  {:ok, listener} = Listener.start(port: input_port)

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

  @doc """
  Stops listening to the MIDI input port by unsubscribing to it.

  Note that this stops the Rust OS thread from sending messages from that port. If other Elixir processes have also subscribed to that port, they will also stop recieving messages.
  """
  def unsubscribe(pid, midi_input_port) do
    GenServer.cast(pid, {:unsubscribe, midi_input_port})
  end

  @doc """
  Stops listening to all input ports.
  """
  def unsubscribe_all(pid) do
    GenServer.cast(pid, :unsubscribe_all)
  end

  @doc """
  Subscribe to one or more MIDI input ports.
  """
  def subscribe(pid, midi_input_port) do
    GenServer.cast(pid, {:subscribe, midi_input_port})
  end

  @doc """
  Get the servers state, returns `%Midiex.Server{}` struct.
  """
  def get_state(pid) do
    GenServer.call(pid, :state)
  end

  # @doc """
  # Start the inport port listening for callback execution loop.
  # """
  # def poll(pid) do
  #   schedule_poller(pid)
  # end

  # ----------------
  # Helper functions
  # ----------------

  defp ports_equal?(port_one, port_two), do: (port_one.name == port_two.name) && (port_one.num == port_two.num)



end
