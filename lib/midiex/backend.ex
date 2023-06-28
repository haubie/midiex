defmodule Midiex.Backend do
  @moduledoc false

  # alias Hex.API.Key

  use Rustler,
    otp_app: :midiex,
    crate: :midiex

  # ##########
  # NATIVE API
  # ##########

  def test(_midi_port), do: err()

  # MIDI port functions
  def list_ports(), do: err()
  def count_ports(), do: err()
  def connect(_midi_port), do: err()
  def close_out_conn(_out_conn), do: err()
  def create_virtual_output_conn(_name \\ "MIDIex-virtual-output"), do: err()
  def create_virtual_input_conn(_name \\ "MIDIex-virtual-input"),  do: err()

  # MIDI messaging functions
  def send_msg(_out_port_conn, _midi_msg), do: err()

  # Midiex callback functions
  def subscribe(_midi_port), do: err()
  def listen(_input_port), do: err()
  def listen_virtual_input(_name \\ "MIDIex-virtual-input"), do: err()
  def subscribe_to_port(_input_port), do: err()
  def get_subscribed_ports(), do: err()
  def clear_subscribed_ports(), do: err()

  defp err(), do: :erlang.nif_error(:nif_not_loaded)


end
