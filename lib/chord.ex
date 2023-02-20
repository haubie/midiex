defmodule Midiex.Chord do

  def major, do: [3,4,3]
  def minor, do: [3,3,4]
  def dim, do: [3,3,3]
  def aug, do: [3,4,4]


  def play_chord(midi_out_conn, start_note, chord_inverals, duration \\ 1) when is_list(chord_inverals) do

    chord_inverals
    |> Enum.map(fn interval -> <<0x90, start_note + interval, 127>> end)
    |> IO.inspect(label: "on intervals")
    |> Enum.each(fn midi_note_on_msg -> Midiex.send_msg(midi_out_conn, midi_note_on_msg) end )

    :timer.sleep(duration * 150)

    chord_inverals
    |> Enum.map(fn interval -> <<0x80, start_note + interval, 127>> end)
    |> IO.inspect(label: "off intervals")
    |> Enum.each(fn midi_note_off_msg -> Midiex.send_msg(midi_out_conn, midi_note_off_msg) end)
  end


end
