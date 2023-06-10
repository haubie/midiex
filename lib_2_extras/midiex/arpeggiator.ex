defmodule Midiex.Arpeggiator do

  # The arpeggiator is a common synthesizer feature that spits out an arpeggio when you press down a chord.
  # This means you can play any chord (let’s say a basic C major chord: C, E, G, and high C)
  # and the synthesizer will play an arpeggiated sequence — a looping pattern with each of those notes — played one at a time.

  # https://output.com/blog/arpeggiator-basics-guide

  # "Up”: Lowest note to highest note.
  # “Down”: Highest note to lowest note.
  # “Converge”: Lowest note first, then highest note, working its way to the “middle” of the chord.
  # “Diverge”: “Middle” notes first, working its way to the “outside” of the chord (which are the highest and lowest notes).
  # “Random”: Generate a random order of notes.


  def arp(midi_out_conn, start_note, scale, opts\\[]) when is_list(scale) do

    duration  = Keyword.get(opts, :duration, 1)
    direction = Keyword.get(opts, :direction, :asc)

    scale = case direction do
      :asc -> scale
      :up -> scale

      :desc -> Enum.reverse(scale)
      :down -> Enum.reverse(scale)

      :sweep -> scale ++ Enum.reverse(scale)
      :sweep_up -> scale ++ Enum.reverse(scale)

      :sweep_down -> Enum.reverse(scale) ++ scale

      :shuffle -> Enum.shuffle(scale)
      :random -> Enum.shuffle(scale)

      _-> scale
    end


    scale
    |> Enum.each(fn offset ->

      Midiex.send_msg(midi_out_conn, <<0x90, start_note + offset, 127>>)
      :timer.sleep(duration * 150)
      Midiex.send_msg(midi_out_conn, <<0x80, start_note + offset, 127>>)

    end)

  end



end
