defmodule Midiex.Message do
  @moduledoc """
  Conveniences for creating MIDI messages.

  ## About MIDI messages
  MIDI messages are in the format of:

    status_byte + note_number (0-127) + velocity (0-127)

  For example, taking the status byte for Note On which in HEX is `0x90`, and the note Middle C which is 60 and a maximum key velocity of 127, the MIDI message in binary format is:

    <<0x90, 60, 127>>

  ## MIDI message functions
  So that you don't have to remember all the MIDI message codes, this library has the following functions to generate messages:

  - note_on(note_number, velocity, opts)
  - note_off(note_number, velocity, opts)
  - polyphonic_aftertouch(note_number, pressure, opts)
  - channel_aftertouch(note_number, pressure, opts)
  - control_change(control_number, value, opts)
  - program_change(program_number, opts)
  - pitch_wheel(lsbyte, msbyte, opts)
  - sysex - coming soon

  """


  # status_byte, note_number (0-127), velocity (0-127)
  # midi_note_on_msg = <<0x90, note, 127>>
  # midi_note_off_msg = <<0x80, note, 127>>


  # https://www.inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies

  @notes [
    {"Ab9", 128},
    {"G#9", 128},
    {"G9", 127},
    {"Gb9", 126},
    {"F#9", 126},
    {"F9", 125},
    {"E9", 124},
    {"Eb9", 123},
    {"D#9", 123},
    {"D9", 122},
    {"Db9", 121},
    {"C#9", 121},
    {"C9", 120},
    {"B8", 119},
    {"Bb8", 118},
    {"A#8", 118},
    {"A8", 117},
    {"Ab8", 116},
    {"G#8", 116},
    {"G8", 115},
    {"Gb8", 114},
    {"F#8", 114},
    {"F8", 113},
    {"E8", 112},
    {"Eb8", 111},
    {"D#8", 111},
    {"D8", 110},
    {"Db8", 109},
    {"C#8", 109},
    {"C8", 108},
    {"B7", 107},
    {"Bb7", 106},
    {"A#7", 106},
    {"A7", 105},
    {"Ab7", 104},
    {"G#7", 104},
    {"G7", 103},
    {"Gb7", 102},
    {"F#7", 102},
    {"F7", 101},
    {"E7", 100},
    {"Eb7", 99},
    {"D#7", 99},
    {"D7", 98},
    {"Db7", 97},
    {"C#7", 97},
    {"C7", 96},
    {"B6", 95},
    {"Bb6", 94},
    {"A#6", 94},
    {"A6", 93},
    {"Ab6", 92},
    {"G#6", 92},
    {"G6", 91},
    {"Gb6", 90},
    {"F#6", 90},
    {"F6", 89},
    {"E6", 88},
    {"Eb6", 87},
    {"D#6", 87},
    {"D6", 86},
    {"Db6", 85},
    {"C#6", 85},
    {"C6", 84},
    {"B5", 83},
    {"Bb5", 82},
    {"A#5", 82},
    {"A5", 81},
    {"Ab5", 80},
    {"G#5", 80},
    {"G5", 79},
    {"Gb5", 78},
    {"F#5", 78},
    {"F5", 77},
    {"E5", 76},
    {"Eb5", 75},
    {"D#5", 75},
    {"D5", 74},
    {"Db5", 73},
    {"C#5", 73},
    {"C5", 72},
    {"B4", 71},
    {"Bb4", 70},
    {"A#4", 70},
    {"A4", 69},
    {"Ab4", 68},
    {"G#4", 68},
    {"G4", 67},
    {"Gb4", 66},
    {"F#4", 66},
    {"F4", 65},
    {"E4", 64},
    {"Eb4", 63},
    {"D#4", 63},
    {"D4", 62},
    {"Db4", 61},
    {"C#4", 61},
    {"MiddleC", 60},
    {"C4", 60},
    {"B3", 59},
    {"Bb3", 58},
    {"A#3", 58},
    {"A3", 57},
    {"Ab3", 56},
    {"G#3", 56},
    {"G3", 55},
    {"Gb3", 54},
    {"F#3", 54},
    {"F3", 53},
    {"E3", 52},
    {"Eb3", 51},
    {"D#3", 51},
    {"D3", 50},
    {"Db3", 49},
    {"C#3", 49},
    {"C3", 48},
    {"B2", 47},
    {"Bb2", 46},
    {"A#2", 46},
    {"A2", 45},
    {"Ab2", 44},
    {"G#2", 44},
    {"G2", 43},
    {"Gb2", 42},
    {"F#2", 42},
    {"F2", 41},
    {"E2", 40},
    {"Eb2", 39},
    {"D#2", 39},
    {"D2", 38},
    {"Db2", 37},
    {"C#2", 37},
    {"C2", 36},
    {"B1", 35},
    {"Bb1", 34},
    {"A#1", 34},
    {"A1", 33},
    {"Ab1", 32},
    {"G#1", 32},
    {"G1", 31},
    {"Gb1", 30},
    {"F#1", 30},
    {"F1", 29},
    {"E1", 28},
    {"Eb1", 27},
    {"D#1", 27},
    {"D1", 26},
    {"Db1", 25},
    {"C#1", 25},
    {"C1", 24},
    {"B0", 23},
    {"Bb0", 22},
    {"A#0", 22},
    {"A0", 21},
  ]

  @note_on <<0x9::4>>
  @note_off <<0x8::4>>


    def note(text_note) do
      {_, note} = Enum.find(@notes, fn {note, midi_num} -> note == text_note end)
      note
    end

    def note_on(note, velocity\\127, opts \\ []) do
      channel = Keyword.get(opts, :channel, 0)
      <<@note_on, channel::4, note, velocity>>
    end

    def note_off(note, velocity\\127, opts \\ []) do
      channel = Keyword.get(opts, :channel, 0)
      <<@note_off, channel::4, note, velocity>>
    end

    # def note_off_all(channel) do
    #   # change_control(channel, 123)
    # end


    # NoteOff(note_number, velocity)

    # NoteOn(note_number, velocity)

    # PolyphonicAftertouch(note_number, pressure)

    # ChannelAftertouch(pressure)

    # ControlChange(control_number, value)

    # ProgramChange(program_number)

    # PitchWheel(lsbyte, msbyte)

    # SysEx(manufacturer_id, data1, data2..., dataN)


end
