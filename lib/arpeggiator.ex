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


  def hello(), do: nil




end
