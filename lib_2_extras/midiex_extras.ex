defmodule MidiexExtras do
  @moduledoc """
  Documentation for `Midiex`.
  """
  alias Midiex.Backend
  alias Midiex.Note
  alias Midiex.Chord
  alias Midiex.Scale

  # #######
  # HELPERS
  # #######

  def choose(list), do: Enum.random(list)
  def shuffle(list), do: Enum.shuffle(list)

  @doc """
  Play a MIDI note or a list of notes with a duration. If no duration is given, it is taken as 1 second.
  """
  def play(midi_out_conn, note, duration \\ 1) do
    cond do
      is_number(note) -> play_notes(midi_out_conn, note, duration)
      is_list(note) -> play_notes(midi_out_conn, note, duration)
      true -> play_notes(midi_out_conn, Note.to_number(note), duration)
    end
  end

  @doc """
  Play a pattern of MIDI notes.
  """
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
      Midiex.Time.wait(duration)
      Midiex.send_msg(midi_out_conn, <<0x80, note, 127>>)

    end)

  end

  @doc """
  Generate a chord from a base note.
  """
  def chord(base_note, chord_type) do
    cond do
      is_number(base_note) -> Chord.generate_notes(base_note, chord_type)
      true ->  Note.to_number(base_note) |> Chord.generate_notes(chord_type)
    end

  end

  @doc """
  Generate a scale from a base note.
  """
  def scale(base_note, scale_type, opt \\ []) do
    cond do
      is_number(scale_type) -> Scale.notes(base_note, scale_type, opt)
      true -> Note.to_number(base_note) |>  Scale.notes(scale_type, opt)
    end
  end

  @doc """
  Play a series of notes.
  """
  def play_notes(midi_out_conn, notes, duration \\ 1) do

    notes = if is_number(notes), do: [notes], else: notes

    notes
    |> Enum.map(fn note -> <<0x90, note, 127>> end)
    |> Enum.each(fn midi_note_on_msg -> Midiex.send_msg(midi_out_conn, midi_note_on_msg) end )

    Midiex.Time.wait(duration)

    notes
    |> Enum.map(fn note -> <<0x80, note, 127>> end)
    |> Enum.each(fn midi_note_off_msg -> Midiex.send_msg(midi_out_conn, midi_note_off_msg) end)
  end


  @doc """
  Play a single note with a duration.
  """
  def play_note(midi_out_conn, note, duration \\ 1) do
    midi_note_on_msg = <<0x90, note, 127>>

    midi_out_conn
    |> send_msg(midi_note_on_msg)
    |> tap(fn _ -> Midiex.Time.wait(duration) end)
    |> stop_note(note)

  end

  @doc """
  Stop a note.
  """
  def stop_note(midi_out_conn, note) do
    midi_note_off_msg = <<0x80, note, 127>>
    send_msg(midi_out_conn, midi_note_off_msg)
  end

  def play_example_song(midi_out_conn) do
    midi_out_conn
    |> play_note(66, 4*0.25)
    |> play_note(65, 3*0.25)
    |> play_note(63, 1*0.25)
    |> play_note(61, 6*0.25)
    |> play_note(59, 2*0.25)
    |> play_note(58, 4*0.25)
    |> play_note(56, 4*0.25)
    |> play_note(54, 4*0.25)
  end


end
