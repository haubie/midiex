defmodule Midiex do
  @moduledoc """
  Documentation for `Midiex`.
  """
alias Hex.API.Key

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

  # MIDI messaging functions
  def play(_conn), do: err()
  def send_msg(_out_port_conn, _midi_msg), do: err()

  # Midiex callback functions
  def subscribe(), do: err()


  defp err(), do: :erlang.nif_error(:nif_not_loaded)

  # #######
  # HELPERS
  # #######
  def filter_port_name_contains(ports_list, name, opts \\ []) do
    direction = Keyword.get(opts, :direction)
    ports_list
    |> Enum.filter(fn port -> String.contains?(port.name, name) end)
    |> filter_port_direction(direction)
  end

  def filter_port_direction(ports_list, nil), do: ports_list

  def filter_port_direction(ports_list, direction) do
    ports_list
    |> Enum.filter(fn port -> port.direction == direction end)
  end

  def get_first_output_port(ports_list) do
    ports_list
    |> filter_port_direction(:output)
    |> List.first()
  end


  # ##########
  # OLD API
  # ##########

  # def new(), do: get_midi_io()
  # def get_midi_io(), do: err()
  # def try_connect(_ref), do: err()

   def try_core_midi(), do: err()
  #  def play_test(), do: err()
end
