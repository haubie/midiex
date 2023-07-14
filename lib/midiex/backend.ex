defmodule Midiex.Backend do
  @moduledoc false

  # alias Hex.API.Key

  use Rustler,
    otp_app: :midiex,
    crate: :midiex

  # ##########
  # NATIVE API
  # ##########

  # MIDI port functions
  def list_ports(), do: err()
  def count_ports(), do: err()
  def connect(_midi_port), do: err()
  def close_out_conn(_out_conn), do: err()
  def create_virtual_output_conn(_name \\ "MIDIex-virtual-output"), do: err()
  def create_virtual_input(_name \\ "MIDIex-virtual-input"), do: err()

  # MIDI messaging functions
  def send_msg(_out_port_conn, _midi_msg), do: err()

  # Midiex callback functions
  def subscribe(_midi_port), do: err()
  def unsubscribe_all_ports(), do: err()
  def unsubscribe_port(_midi_port), do: err()
  def unsubscribe_port_by_index(_port_index), do: err()

  def subscribe_virtual_input(_name \\ "MIDIex-virtual-input"), do: err()
  def unsubscribe_virtual_port(_name), do: err()
  def unsubscribe_all_virtual_ports(), do: err()
  def get_subscribed_ports(), do: err()
  def get_subscribed_virtual_ports(), do: err()

  def notifications(), do: err()
  def hotplug(), do: err()


  defp err(), do: :erlang.nif_error(:nif_not_loaded)


end
