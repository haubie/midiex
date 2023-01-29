defmodule Midiex do
  @moduledoc """
  Documentation for `Midiex`.
  """

  use Rustler,
    otp_app: :midiex,
    crate: :midiex

  # def new(), do: get_midi_io()
  # def get_midi_io(), do: err()
  def list_ports(), do: err()
  def count_ports(), do: err()

  def try_connect(_ref), do: err()
  def connect(_midi_port), do: err()

  def try_core_midi(), do: err()

  def play(), do: err()
  def play_two(_conn), do: err()

  def subscribe(), do: err()

  defp err(), do: :erlang.nif_error(:nif_not_loaded)

end
