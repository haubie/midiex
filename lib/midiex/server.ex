defmodule Midiex.Server do

  use GenServer

  defstruct listener_callback_fns: []

  @impl true
  def init(state \\ %__MODULE__{}) do
    schedule_poller(self())
    {:ok, state}
  end

  @impl true
  def handle_cast({:add_handler, input_port, handler_fn}, state) do
    new_state = %__MODULE__{state | listener_callback_fns: [{input_port, handler_fn}] ++ state.listener_callback_fns}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:remove, input_port}, state) do
    new_state = %__MODULE__{state | listener_callback_fns: Enum.reject(state.listener_callback_fns, fn {port, _cb_fn} -> ports_equal?(port, input_port) end)}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:remove_all, state) do
    new_state = %__MODULE__{state | listener_callback_fns: []}
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:poll, state) do
    state = check_and_action_midi_msgs(state)
    schedule_poller(self())
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
  def new(opts \\ []), do: struct(__MODULE__, opts)

  @doc """
  Start the Midiex.Server GenServer.

  Takes an optional keyword list as the first parameter which can be used to populate individual %Midiex.Server{} struct keys. See `new/1` for informaton.
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
  """
  def add_handler(pid, input_port, handler_fn) do
    GenServer.cast(pid, {:add_handler, input_port, handler_fn})
  end

  @doc """
  Stops listening to an input port by removing callback hander(s) for it.
  """
  def remove(pid, input_port) do
    GenServer.cast(pid, {:remove, input_port})
  end

  @doc """
  Stops listening to all input ports by removing callback hander(s) for it.
  """
  def remove_all(pid) do
    GenServer.cast(pid, :remove_all)
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

  defp check_and_action_midi_msgs(state) do
    state.listener_callback_fns
    |> Enum.each(fn {in_port, callback_fn} ->
      IO.inspect "Message loop"
      IO.inspect in_port, label: "Checking for"
      msg = Midiex.listen(in_port)
      IO.inspect msg, label: "MSG"
      maybe_callback(msg, callback_fn)
    end)

    state
  end

  defp maybe_callback([], _callback_fn), do: nil
  defp maybe_callback(msg, callback_fn), do: callback_fn.(msg)

  defp schedule_poller(pid) do
    # send self(), :poll
    Process.send_after(pid, :poll, 3000)
  end

end
