defmodule Midiex.Notifier do
  @moduledoc """
  GenServer for subscribing and responding to MIDI notifications on supported systems.

  This is currently implemented for Mac only.

  ## How this works
  On Mac, a callback function needs to be created to specially handle MIDI notification messages, such as when a device has been physically plugged (`:added`) or unplugged (`:removed`). This callback is implemented in the Rust side of this library.
  The notifications will be delivered on MacOS to a Rust thread with the specific 'run loop' that was created when the `Midiex.notifications/0` function was first called. This function is called automatically when this GenServer is started.

  Any (`:added`) or (`:removed`) notifications will be sent to this GenServer from the Rust thread.

  The `Midiex.Notifier` GenServer then forwards these notifications to any handlers added in with the `add_handler/2` function or passed to it through the `start/1` function.

  ## Example
  ```
  # Start the Notifier GenServer
  {:ok, pid} = Midiex.Notifier.start()

  # Add a simple handler callback function. This will just inspect the notification.
  Midiex.Notifier.add_handler(pid, fn msg -> IO.inspect(msg) end)

  # KeyStep Pro keyboard has been hot-plugged into the Mac:
  %Midiex.MidiNotification{
    notification_type: :added,
    parent_name: "KeyStep Pro",
    parent_id: 1384647386,
    parent_type: :entity,
    name: "KeyStep Pro",
    native_id: 493507367,
    direction: :input
  }
  %Midiex.MidiNotification{
    notification_type: :added,
    parent_name: "KeyStep Pro",
    parent_id: 1384647386,
    parent_type: :entity,
    name: "KeyStep Pro",
    native_id: 2688501783,
    direction: :output
  }

  # KeyStep Pro keyboard has been unplugged into the Mac:
  %Midiex.MidiNotification{
    notification_type: :removed,
    parent_name: "KeyStep Pro",
    parent_id: 1384647386,
    parent_type: :entity,
    name: "KeyStep Pro",
    native_id: 493507367,
    direction: :input
  }
  %Midiex.MidiNotification{
    notification_type: :removed,
    parent_name: "KeyStep Pro",
    parent_id: 1384647386,
    parent_type: :entity,
    name: "KeyStep Pro",
    native_id: 2688501783,
    direction: :output
  }
  ```
  """

  use GenServer

  defstruct callback: []

  @impl true
  def init(state \\ %__MODULE__{}) do
    Midiex.Backend.notifications()
    {:ok, state}
  end

  @impl true
  def handle_cast({:add_handler, handler_fn}, state) do
    handler_fn = if is_list(handler_fn), do: handler_fn, else: [handler_fn]
    new_state = %__MODULE__{state | callback: handler_fn ++ state.callback}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:clear_handlers, state) do
    new_state = %__MODULE__{state | callback: []}
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(info, state) do
    state.callback
    |> Enum.each(fn callback_fn -> callback_fn.(info) end)

    {:noreply, state}
  end

  # ---
  # API
  # ---

  @doc """
  Creates a new %Midiex.Notifier{} struct.

  Takes an optional keyword list as the first parameter which can be used to populate individual struct keys.

  The struct holds the following key-values:
  - `:callback` which holds a list of functions called when a message is received for an input port. The callback must be of single arity and take it's first parameter a message. See `add_handler/2` for an example.
  """
  def new(opts \\ []) do
    callback =
      case Keyword.get(opts, :callback) do
        callbacks when is_list(callbacks) -> callbacks
        callback when is_function(callback) -> [callback]
        _ -> []
      end

    %__MODULE__{callback: callback}
  end


  @spec start(keyword) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Start the Midiex.Notifier GenServer.

  Takes an optional keyword list as the first parameter which can be used to populate individual %Midiex.Notifier{} struct keys. See `new/1` for informaton.
  """
  def start(opts \\ []) do
    GenServer.start_link(__MODULE__, new(opts))
  end


  @spec add_handler(pid(), function() | [function()]) :: :ok
  @doc """
  Add one or more callback function(s) which will recieve and handle MIDI notifications.

  The first parameter of the callback function will be used to recieve notification messages.

  ## Example
  ```
  # Start the Notifier GenServer
  {:ok, pid} = Midiex.Notifier.start()

  # Add a simple handler callback function. This will just inspect the notification.
  Midiex.Notifier.add_handler(pid, fn msg -> IO.inspect(msg) end)
  ```
  """
  def add_handler(pid, handler_fn) do
    GenServer.cast(pid, {:add_handler, handler_fn})
  end

  @doc """
  Clears all handlers.
  """
  def clear_handlers(pid) do
    GenServer.cast(pid, :clear_handlers)
  end

  @spec get_state(pid()) :: %Midiex.Listener{}
  @doc """
  Gets the servers state, returns `%Midiex.Listener{}` struct.
  """
  def get_state(pid) do
    GenServer.call(pid, :state)
  end


end
