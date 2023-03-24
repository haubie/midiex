defmodule Midiex.Backend do
  @moduledoc """
  Documentation for `Midiex`.
  """
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

  # MIDI messaging functions
  def send_msg(_out_port_conn, _midi_msg), do: err()

  # Midiex callback functions
  def subscribe(), do: err()
  def listen(_input_port), do: err()


  defp err(), do: :erlang.nif_error(:nif_not_loaded)


end
