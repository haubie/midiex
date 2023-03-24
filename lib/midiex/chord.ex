defmodule Midiex.Chord do

  @chord_interverals [
    major: [0, 4, 7],
    M: [0, 4, 7],
    minor: [0, 3, 7],
    m: [0, 3, 7],
    major7: [0, 4, 7, 11],
    dom7: [0, 4, 7, 10],
    minor7: [0, 3, 7, 10],
    aug: [0, 4, 8],
    dim: [0, 3, 6],
    dim7: [0, 3, 6, 9],
    halfdim: [0, 3, 6, 10],
    halfdiminished: [0, 3, 6, 10],
    sus2: [0, 2, 7],
    "6": [0, 4, 7, 9],
    m6: [0, 3, 7, 9],
    "7sus2": [0, 2, 7, 10],
    "7sus4": [0, 5, 7, 10],
    "7-5": [0, 4, 6, 10],
    "7+5": [0, 4, 8, 10],
    "m7+5": [0, 3, 8, 10],
    "9": [0, 4, 7, 10, 14],
    m9: [0, 3, 7, 10, 14],
    "m7+9": [0, 3, 7, 10, 14],
    maj9: [0, 4, 7, 11, 14],
    "9sus4": [0, 5, 7, 10, 14],
    "6*9": [0, 4, 7, 9, 14],
    "m6*9": [0, 3, 7, 9, 14],
    "7-9":  [0, 4, 7, 10, 13],
    "m7-9":  [0, 3, 7, 10, 13],
    "7-10":  [0, 4, 7, 10, 15],
    "7-11":  [0, 4, 7, 10, 16],
    "7-13":  [0, 4, 7, 10, 20],
    "9+5":  [0, 10, 13],
    "m9+5":  [0, 10, 14],
    "7+5-9":  [0, 4, 8, 10, 13],
    "m7+5-9":  [0, 3, 8, 10, 13],
    "11": [0, 4, 7, 10, 14, 17],
    m11:    [0, 3, 7, 10, 14, 17],
    maj11:  [0, 4, 7, 11, 14, 17],
    "11+":   [0, 4, 7, 10, 14, 18],
    "m11+":  [0, 3, 7, 10, 14, 18],
    "13":    [0, 4, 7, 10, 14, 17, 21],
    m13:          [0, 3, 7, 10, 14, 17, 21],
    add2:         [0, 2, 4, 7],
    add4:         [0, 4, 5, 7],
    add9:         [0, 4, 7, 14],
    add11:        [0, 4, 7, 17],
    add13:        [0, 4, 7, 21],
    madd2:        [0, 2, 3, 7],
    madd4:        [0, 3, 5, 7],
    madd9:        [0, 3, 7, 14],
    madd11:       [0, 3, 7, 17],
    madd13:       [0, 3, 7, 21],
  ]

  def generate_notes(start_note, chord_type) do
    @chord_interverals[chord_type]
    |> Enum.map(fn interval -> start_note + interval end)
  end


  def play(midi_out_conn, notes, duration \\ 1) when is_list(notes) do

    notes
    |> Enum.map(fn note -> <<0x90, note, 127>> end)
    |> Enum.each(fn midi_note_on_msg -> Midiex.send_msg(midi_out_conn, midi_note_on_msg) end )

    :timer.sleep(duration * 150)

    notes
    |> Enum.map(fn note -> <<0x80, note, 127>> end)
    |> Enum.each(fn midi_note_off_msg -> Midiex.send_msg(midi_out_conn, midi_note_off_msg) end)
  end


  @spec play_interval(any, any, maybe_improper_list, non_neg_integer) :: :ok
  def play_interval(midi_out_conn, start_note, chord_inverals, duration \\ 1) when is_list(chord_inverals) do

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
