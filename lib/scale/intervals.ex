defmodule Midiex.Scale.Interval do

  def generate_notes(start_note, num_notes, intervals) do

    {seq, _acc} =
      intervals
      |> Stream.cycle()
      |> Enum.take(num_notes)
      |> Enum.map_reduce(start_note, fn offset, acc ->

        next_note = acc + offset
        {acc, next_note}

        end)

    seq
  end

  def generate_notes(start_note, num_notes, intervals, callback_function) do
    intervals
    # |> Enum.drop(1)
    |> Stream.cycle()
    |> Enum.take(num_notes)
    |> Enum.map_reduce(start_note, fn offset, acc ->
      ret = {offset, acc+offset};
      callback_function.(acc);
      ret end)
  end





   # Intervals

   def dorian, do: [2,1,2,2,2,1,2]
   def phrygian, do: [1,2,2,2,1,2,2]
   def lydian, do: [2,2,2,1,2,2,1]
   def mixolydian, do: [2,2,1,2,2,1,2]
   def aeolian, do: [2,1,2,2,1,2,2]
   def locrian, do: [1,2,2,1,2,2,2]

   def lydian_domiant, do: [2,2,2,1,2,1,2]
   def super_locrian, do: [1,2,1,2,2,2,2]

   def minor_pentatonic, do: [3,2,2,3,2]
   def major_pentatonic, do: [2,2,3,2,3]
   def minor_blues, do: [3,2,1,1,3,2]
   def major_blues, do: [2,1,1,3,2,3]

   def whole_half_diminished, do: [2,1,2,1,2,1,2,1]
   def half_whole_diminished, do: [1,2,1,2,1,2,1,2]

   def major, do: [2,2,1,2,2,2,1]

end
