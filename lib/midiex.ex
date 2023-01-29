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
  def list_ports(direction), do: filter_port_direction(list_ports(), direction)
  def list_ports(), do: err()
  def count_ports(), do: err()
  def connect(_midi_port), do: err()


  def create_virtual_output(), do: err()

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

  def play_note(midi_out_conn, note, duration \\ 1) do
    midi_note_on_msg = <<0x90, note, 127>>

    midi_out_conn
    |> send_msg(midi_note_on_msg)
    |> tap(fn _ -> :timer.sleep(duration * 150) end)
    |> stop_note(note)

  end

  def stop_note(midi_out_conn, note) do
    midi_note_off_msg = <<0x80, note, 127>>
    send_msg(midi_out_conn, midi_note_off_msg)
  end


  def example_song(midi_out_conn) do
    midi_out_conn
    |> play_note(66, 4)
    |> play_note(65, 3)
    |> play_note(63, 1)
    |> play_note(61, 6)
    |> play_note(59, 2)
    |> play_note(58, 4)
    |> play_note(56, 4)
    |> play_note(54, 4)
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
