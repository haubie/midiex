defmodule Midiex do
  @moduledoc """
  Documentation for `Midiex`.
  """
# alias Hex.API.Key

  alias Midiex.Backend
  alias Midiex.Note
  alias Midiex.Chord
  alias Midiex.Scale

  # ##########
  # NATIVE API
  # ##########

  # MIDI port functions

  def list_ports(), do: Backend.list_ports()
  def list_ports(direction) when is_atom(direction), do: filter_port_direction(list_ports(), direction)
  def list_ports(name, direction \\ nil) when is_binary(name) do
    filter_port_name_contains(list_ports(), name, direction: direction)
  end
  def count_ports(), do: Backend.count_ports()
  def connect(midi_port), do: Backend.connect(midi_port)
  def close_out_conn(out_conn), do: Backend.close_out_conn(out_conn)

  def create_virtual_output_conn(name), do: Backend.create_virtual_output_conn(name)



  # MIDI messaging functions
  def send_msg(out_port_conn, midi_msg), do: Backend.send_msg(out_port_conn, midi_msg)

  # Midiex callback functions
  def subscribe(), do: Backend.subscribe()
  def listen(input_port), do: Backend.listen(input_port)



  # #######
  # HELPERS
  # #######
  @spec filter_port_name_contains(any, any, keyword) :: any
  def filter_port_name_contains(ports_list, name, opts \\ []) do
    direction = Keyword.get(opts, :direction, nil)
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

  def choose(list), do: Enum.random(list)
  def shuffle(list), do: Enum.shuffle(list)

  def play(midi_out_conn, note) when is_number(note), do: play_notes(midi_out_conn, note)
  def play(midi_out_conn, note) when is_list(note), do: play_notes(midi_out_conn, note)
  def play(midi_out_conn, note), do: play_notes(midi_out_conn, Note.to_number(note))

  def play_pattern(midi_out_conn, notes, timing \\ [1], opts \\ []) do

    direction = Keyword.get(opts, :direction, :asc)

    timing = if is_number(timing), do: [timing], else: timing

    notes = case direction do
      :asc -> notes
      :up -> notes

      :desc -> Enum.reverse(notes)
      :down -> Enum.reverse(notes)

      :sweep ->
        [_h | t] = Enum.reverse(notes)
        notes ++ t

      :sweep_up ->
        [_h | t] = Enum.reverse(notes)
        notes ++ t

      :sweep_down ->
        [_h | t] = notes
        Enum.reverse(notes) ++ t

      :shuffle -> Enum.shuffle(notes)
      :random -> Enum.shuffle(notes)

      _-> notes
    end


    duration_pattern =
      timing
      |> Stream.cycle()
      |> Enum.take(length(notes))


    [notes, duration_pattern]
    |> Enum.zip()
    |> Enum.each(fn {note, duration} ->

      Midiex.send_msg(midi_out_conn, <<0x90, note, 127>>)
      :timer.sleep(duration * 150)
      Midiex.send_msg(midi_out_conn, <<0x80, note, 127>>)

    end)

  end




  def chord(base_note, chord_type) when is_number(base_note) do
     Chord.generate_notes(base_note, chord_type)
  end
  def chord(base_note, chord_type) do
    Note.to_number(base_note) |> Chord.generate_notes(chord_type)
  end



  def scale(base_note, scale_type) when is_number(base_note), do: Scale.notes(base_note, scale_type)
  def scale(base_note, scale_type) do
    Note.to_number(base_note) |>  Scale.notes(scale_type)
  end



  def play_notes(midi_out_conn, notes, duration \\ 1) do

    notes = if is_number(notes), do: [notes], else: notes

    notes
    |> Enum.map(fn note -> <<0x90, note, 127>> end)
    |> Enum.each(fn midi_note_on_msg -> Midiex.send_msg(midi_out_conn, midi_note_on_msg) end )

    :timer.sleep(duration * 150)

    notes
    |> Enum.map(fn note -> <<0x80, note, 127>> end)
    |> Enum.each(fn midi_note_off_msg -> Midiex.send_msg(midi_out_conn, midi_note_off_msg) end)
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


  def play_example_song(midi_out_conn) do
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


end
