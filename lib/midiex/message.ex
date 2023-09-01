defmodule Midiex.Message do

  # References
  # https://anotherproducer.com/online-tools-for-musicians/midi-cc-list/
  # https://docs.rs/midi-msg/latest/midi_msg/enum.ChannelVoiceMsg.html

  @moduledoc """
  Convenience functions for creating binary MIDI messages.

  ## MIDI message functions
  So that you don't have to remember all the MIDI message codes, this library has a large range of message generating functions. Some common types are below:

  - `note_on/3`
  - `note_off/3`
  - `all_notes_off/1`
  - `sound_off/1`
  - `polyphonic_aftertouch/3`
  - `channel_aftertouch/3`
  - `control_change/3`
  - `program_change/2`
  - `pitch_bend/2`
  - `pan/2`
  - `volume/2`

  Various system messages are supported too, such as `sysex/1`.

  Some functions have an optional high-resolution (14-bit) version. This is activated by providing the `high_res: true` option, e.g.:  `Midiex.Message.volume(16383, high_res: true)`. You can learn more about the resolution of MIDI messages below.

  ## Notes
  Functions that take notes as a parameter can accept a number, string or atom note representation. For example, middle-C can be represented as `60`, `"C4"` or `:C4`.

  Taking the `note_on/1` function as an example, generating a "note on" MIDI message for middle-C `<<144, 60, 127>>` can be achieved in any of these ways:
  - `Message.note_on(60)`
  - `Message.note_on("C4")`
  - `Message.note_on(:C4)`

  To get the MIDI number for a string or atom note representation, see `note/1`.

  ## Example
  ```
  alias Midiex.Message, as: M
  # Connect to the synth, in this case the Arturia MicroFreak synth
  synth = Midiex.ports("Arturia MicroFreak", :output) |> Midiex.open()

  # Send the note on message, for D3
  Midiex.send_msg(synth, M.note_on(:D3))

  # Wait 1 second
  :timer.sleep(1000)

  # Send the note off message, for D3
  Midiex.send_msg(synth, M.note_off(:D3))
  ```

  ## About MIDI messages
  MIDI messages are in the format of:

    status_byte + note_number (0-127) + velocity (0-127)

  For example, taking the status byte for Note On which in HEX is `0x90`, and the note Middle C which is 60 and a maximum key velocity of 127, the MIDI message in binary format is:

    `<<0x90, 60, 127>>`

  ## Resolution (bits)
  ### Coarse resolution
  This type of message format is sometimes called 'coarse' or 7-bit MIDI, as it takes a maximum of 128 values only (from 0 to 127).

  ### High resolution
  However, 'high resolution' or 14-bit MIDI messages are possible, giving a maximum of 16,384 values (from 0 to 16,383). When working with controllers such as mod wheels, it allows for finer and smoother changes.

  To achieve this higher 14-bit resolution, the MIDI message combines two 7-bit values called:
  - **MSB (Most Significant Byte)**, which is used for 'coarser' values. This is the bit which has the greatest effect.
  - **LSB (Least Significant Byte)**, which is used for 'finer' values.

  In Elixir, We can unpack a 14-bit value into it's MSB and LSB bits using binary pattern matching, e.g.:

  `<<msb::7, lsb::7>> = <<value::14>>`

  The MSB and LSB values are sent as two different messages. Below is what it would look like for a Mod wheel which uses two control change command messages (`0x01` and `0x21`) to send the MSB and LSB respectively
  ```
  <<msb::7, lsb::7>> = <<mod_wheel_value::14>>
  msb_binary = control_change(1, msb)
  lsb_binary = control_change(0x21, lsb)
  <<msb_binary::binary, lsb_binary::binary>>
  ```

  ## More information
  https://www.midi.org/midi-articles/about-midi-part-3-midi-messages
  """


  # http://www.midibox.org/dokuwiki/doku.php?id=midi_specification
  # https://www.inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies

  import Bitwise

  @notes_string_list [
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

  @notes_atom_list [
    Ab9: 128,
    Gs9: 128,
    G9: 127,
    Gb9: 126,
    Fs9: 126,
    F9: 125,
    E9: 124,
    Eb9: 123,
    Ds9: 123,
    D9: 122,
    Db9: 121,
    Cs9: 121,
    C9: 120,
    B8: 119,
    Bb8: 118,
    As8: 118,
    A8: 117,
    Ab8: 116,
    Gs8: 116,
    G8: 115,
    Gb8: 114,
    Fs8: 114,
    F8: 113,
    E8: 112,
    Eb8: 111,
    Ds8: 111,
    D8: 110,
    Db8: 109,
    Cs8: 109,
    C8: 108,
    B7: 107,
    Bb7: 106,
    As7: 106,
    A7: 105,
    Ab7: 104,
    Gs7: 104,
    G7: 103,
    Gb7: 102,
    Fs7: 102,
    F7: 101,
    E7: 100,
    Eb7: 99,
    Ds7: 99,
    D7: 98,
    Db7: 97,
    Cs7: 97,
    C7: 96,
    B6: 95,
    Bb6: 94,
    As6: 94,
    A6: 93,
    Ab6: 92,
    Gs6: 92,
    G6: 91,
    Gb6: 90,
    Fs6: 90,
    F6: 89,
    E6: 88,
    Eb6: 87,
    Ds6: 87,
    D6: 86,
    Db6: 85,
    Cs6: 85,
    C6: 84,
    B5: 83,
    Bb5: 82,
    As5: 82,
    A5: 81,
    Ab5: 80,
    Gs5: 80,
    G5: 79,
    Gb5: 78,
    Fs5: 78,
    F5: 77,
    E5: 76,
    Eb5: 75,
    Ds5: 75,
    D5: 74,
    Db5: 73,
    Cs5: 73,
    C5: 72,
    B4: 71,
    Bb4: 70,
    As4: 70,
    A4: 69,
    Ab4: 68,
    Gs4: 68,
    G4: 67,
    Gb4: 66,
    Fs4: 66,
    F4: 65,
    E4: 64,
    Eb4: 63,
    Ds4: 63,
    D4: 62,
    Db4: 61,
    Cs4: 61,
    MiddleC: 60,
    C4: 60,
    B3: 59,
    Bb3: 58,
    As3: 58,
    A3: 57,
    Ab3: 56,
    Gs3: 56,
    G3: 55,
    Gb3: 54,
    Fs3: 54,
    F3: 53,
    E3: 52,
    Eb3: 51,
    Ds3: 51,
    D3: 50,
    Db3: 49,
    Cs3: 49,
    C3: 48,
    B2: 47,
    Bb2: 46,
    As2: 46,
    A2: 45,
    Ab2: 44,
    Gs2: 44,
    G2: 43,
    Gb2: 42,
    Fs2: 42,
    F2: 41,
    E2: 40,
    Eb2: 39,
    Ds2: 39,
    D2: 38,
    Db2: 37,
    Cs2: 37,
    C2: 36,
    B1: 35,
    Bb1: 34,
    As1: 34,
    A1: 33,
    Ab1: 32,
    Gs1: 32,
    G1: 31,
    Gb1: 30,
    Fs1: 30,
    F1: 29,
    E1: 28,
    Eb1: 27,
    Ds1: 27,
    D1: 26,
    Db1: 25,
    Cs1: 25,
    C1: 24,
    B0: 23,
    Bb0: 22,
    As0: 22,
    A0: 21,
  ]

  @note_on <<0x9::4>>
  @note_off <<0x8::4>>

  @doc """
  Returns the MIDI numerical code for a note.

  Takes either a string or atom representation of a note as the first parameter.

  ## Example
  ```
  # Return the code for middle-C (also known as C4)
  Message.note(:C4)
  Message.note("C4")
  Message.note(:MiddleC)
  Message.note("MiddleC")

  # These all return: 60

  # Return the code for A-sharp 3
  Message.note(:As3)
  Message.note("A#3")

  # These both return: 58
  ```
  """
  def note(num_note) when is_number(num_note), do: num_note
  def note(text_note) when is_binary(text_note) do
    {_, note} = Enum.find(@notes_string_list, fn {note, _midi_num} -> note == text_note end)
    note
  end
  def note(atom_note) when is_atom(atom_note) do
    {_, note} = Enum.find(@notes_atom_list, fn {note, _midi_num} -> note == atom_note end)
    note
  end

  @doc section: :channel_voice
  @spec note_on(atom | binary | number, keyword) :: <<_::24>>
  @doc """
  Creates a MIDI note-on message.

  Takes as it's parameters:
  1. note: a note as a string (e.g. "C4"), atom (e.g. :C4) or number (e.g. 60) as the first parameter
  2. velocity: a number between 0 and 127 representing how hard (or loud) a key was pressed. By defaut 127 is used.

  The following options can be passed:
  - channel: the MIDI channel to which the message will be sent (there are 16 channels per MIDI device, in the range 0 to 15). By default channel 0 is used.

  Note that MIDI channels are in the range 0 - 15. But in MIDI software and hardware it may be offset by +1, so MIDI channel 0 might be called MIDI channel 1 and so on to channel 16.

  ## Examples
  ```
  # Note-on message for middle-C
  Midiex.Message.note_on(:C4)

  # Returns: <<144, 60, 127>>

  # Note-on message for middle-C on channel 2 with a velocity of 40
  Midiex.Message.note_on(:C4, 40, channel: 2)

  # Returns: <<146, 60, 40>>
  ```

  These can be sent to a connection using `Midiex.send_msg/2`, for example:
  ```
  alias Midiex.Message
  Midiex.send_msg(out_conn, Message.note_on(:C4, 40, channel: 2))
  ```
  """
  def note_on(note, velocity \\ 127, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<@note_on, channel::4, note(note), velocity>>
  end

  @doc section: :channel_voice
  @doc """
  Creates a MIDI note-off message.

  Takes as it's parameters:
  1. note: a note as a string (e.g. "C4"), atom (e.g. :C4) or number (e.g. 60) as the first parameter
  2. velocity: a number between 0 and 127 representing how hard (or loud) a key was pressed. By defaut 127 is used.

  The following options can be passed:
  - channel: the MIDI channel to which the message will be sent (there are 16 channels per MIDI device, in the range 0 to 15). By default channel 0 is used.

  All notes can be switched off with `Message.all_notes_off/1`.

  ## Example
  ```
  # Note-off for middle-C
  Message.note_off(:C4)

  # Returns: <<128, 60, 127>>
  ```
  """
  def note_off(note, velocity \\ 123, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<@note_off, channel::4, note(note), velocity>>
  end

  @doc section: :channel_voice
  @doc """
  Creates a polyphonic aftertouch message.

  On a keyboard, polyphonic aftertouch (or key pressure) is message sent by pressing down further on a key after it has already reached the bottom. Not all keyboards have aftertouch.

  Note: `polyphonic_aftertouch` is specific to each key, where as `channel_aftertouch` is average amount of pressure applied to whichever keys are held down.

  The function takes as it's parameters:
  1. note: a note as a string (e.g. "C4"), atom (e.g. :C4) or number (e.g. 60) as the first parameter
  2. pressure: a number between 0 and 127 representing the pressure on the key. By defaut 127 is used.

  The following options can be passed:
  - channel: the MIDI channel to which the message will be sent (there are 16 channels per MIDI device, in the range 0 to 15). By default channel 0 is used.

  ## Example
  ```
  alias Midiex.Message

  # Create a series of aftertouch messages from 0 to 127 for the note middle-C (C4)
  0..127//1
  |> Enum.map(fn pressure -> Message.polyphonic_aftertouch(:C4, pressure) end)
  ```
  """
  def polyphonic_aftertouch(note, pressure, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<0xA, channel::4, note(note), pressure>>
  end

  @doc section: :channel_voice
  @doc """
  Creates a channel aftertouch (also known as channel pressure) message.

  On a keyboard, an aftertouch message is sent by pressing down further on keys after it has already reached the bottom. Not all keyboards have aftertouch.

  With channel aftertouch, one of the following is used; Either the:
  - average amount of pressure of all the keys held down; or the
  - single greatest pressure value of all the current depressed keys.
  Therefore channel aftertouch is independent of which key or how many keys are held. `polyphonic_aftertouch` is specific to each key however.

  This function takes as it's parameters:
  1. note: a note as a string (e.g. "C4"), atom (e.g. :C4) or number (e.g. 60) as the first parameter
  2. pressure: a number between 0 and 127 representing the pressure on the key. By defaut 127 is used.

  The following option can also be passed:
  - channel: the MIDI channel to which the message will be sent (there are 16 channels per MIDI device, in the range 0 to 15). By default channel 0 is used.

  ## Example
  ```
  alias Midiex.Message

  # Create a series of aftertouch messages from 0 to 127 for the note middle-C (C4)
  0..127//1
  |> Enum.map(fn pressure -> Message.channel_aftertouch(:C4, pressure: pressure) end)
  ```
  """
  def channel_aftertouch(note, pressure, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<0xD, channel::4, note(note), pressure>>
  end

  @doc section: :channel_voice
  @doc """
  Creates a MIDI CC or 'control change' message.

  MIDI Control Change messages are used to control functions in a synthesiser. Controllers include devices such as pedals, levers/sliders, wheels, switches and other control-oriented devices.

  This function takes as its parameters:
  1. contoller number: a number between 0-119. Controller numbers between 120-127 are reserved as "Channel Mode Messages".
  2. value: depends on the control function, but usually is a a number between 0 and 127. See the MIDI 1.0 Control Change Messages Spec or consult the MIDI device manual for specific codes an values.

  The following option can be passed:
  - channel: the MIDI channel to which the message will be sent (there are 16 channels per MIDI device, in the range 0 to 15). By default channel 0 is used.

  ## Example
  The MIDI CC message of `123` equates to "All Notes Off" (a Channel Mode Message), thus stopping all notes being played.
  ```
  # Create a 'all notes off' CC message.
  Midiex.control_change(127)
  ```
  ## Reference
  See the official [MIDI 1.0 Control Change Messages Spec](https://www.midi.org/specifications-old/item/table-3-control-change-messages-data-bytes-2).
  """
  def control_change(control_number, value \\ 0, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<0xB::4, channel::4, control_number, value>>
  end

  @doc section: :channel_voice
  @doc """
  Creates a program change message, used select the instrument type to play sounds with or a different 'patch'.

  This function takes one data byte which specifies the new program number.

  To apply this to a particular channel, use the channel option, e.g.:
  ```
  Message.program_change(1, channel: 3)
  ```
  """
  def program_change(prog_num, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<0xC::4, channel::4, prog_num>>
  end

  @doc section: :channel_voice
  @doc """
  Creates a pitch bend message, representing a change in pitch.

  Pitch bend change messages a usually sent from a keyboard with a pitch bend wheel or lever.

  Takes as it's first parameter, the pitch bend amount. The channel cane be passed as an option.

  The range of a pitch bend is as follows:
  - 0-8191 represent negative bends,
  - 8192 (Hex: 0x2000) is no bend and
  - 8193-16383 are positive bends

  ## Example
  ```
  alias Midiex.Message, as: M

  # Play a note
  Midiex.send_msg(piano, M.note_on(:D3))

  # Bend up, then down, then back to center (8192)
  (Enum.to_list(8193..16383//1) ++ Enum.to_list(8191..0//-1) ++ [8192])
  |> Enum.each(fn pitch -> Midiex.send_msg(piano, M.pitch_bend(pitch)) end)
  ```
  """
  def pitch_bend(bend, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<msb::7, lsb::7>> = <<bend::14>>
    <<0xE::4, channel::4, lsb, msb>>
  end

  @doc section: :control_change
  @doc """
  Creates a bank select (also known as bank switch) message.

  Takes a bank number as it's first parameter, in the range of 0-16383. The number of banks is dependent on the device.

  A channel number can be provided as an option.
  """
  def bank_select(bank, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<msb::7, lsb::7>> = <<bank::14>>
    msb_binary = control_change(0, msb, channel: channel)
    lsb_binary = control_change(0x20, lsb, channel: channel)
    <<msb_binary::binary, lsb_binary::binary>>
  end

  @doc section: :control_change
  @doc """
  Creates a modulation (mod) wheel message.

  Modulation wheels are often used for vibrato effects (pitch, loudness, brighness), however what is modulated is based on the patch.

  Takes a number as it's first parameter, in the range of 0-16383.

  A channel number can be provided as an option.
  """
  def mod_wheel(bank, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<msb::7, lsb::7>> = <<bank::14>>
    msb_binary = control_change(1, msb, channel: channel)
    lsb_binary = control_change(0x21, lsb, channel: channel)
    <<msb_binary::binary, lsb_binary::binary>>
  end

  @doc section: :control_change
  @doc """
  Creates a breath controller messsage.

  Breath controller messages were originally intended for use with a breath MIDI controller. Blowing harder into the breath controller would produce higher MIDI control values.

  Outside of breath control, is can be associated with aftertouch messages or used for modulation.

  Takes a number as it's first parameter, in the range of 0-16383.

  A channel number can be provided as an option.
  """
  def breath_controller(value, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<msb::7, lsb::7>> = <<value::14>>
    msb_binary = control_change(2, msb, channel: channel)
    lsb_binary = control_change(0x22, lsb, channel: channel)
    <<msb_binary::binary, lsb_binary::binary>>
  end

  @doc section: :control_change
  @doc """
  Creates a foot or pedal controller messsage.

  Takes a number as it's first parameter, in the range of 0-16383.

  A channel number can be provided as an option.
  """
  def foot_controller(value, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<msb::7, lsb::7>> = <<value::14>>
    msb_binary = control_change(4, msb, channel: channel)
    lsb_binary = control_change(0x24, lsb, channel: channel)
    <<msb_binary::binary, lsb_binary::binary>>
  end

  @doc section: :control_change
  @doc """
  Creates a portamento (slide or glide) time	messsage.

  Portamento is the rate to slide between 2 notes played in sequence, sliding the pitch up or down from one note to the next.

  Takes a number as it's first parameter, in the range of 0-16383.

  A channel number can be provided as an option.
  """
  def portamento(value, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    <<msb::7, lsb::7>> = <<value::14>>
    msb_binary = control_change(5, msb, channel: channel)
    lsb_binary = control_change(0x25, lsb, channel: channel)
    <<msb_binary::binary, lsb_binary::binary>>
  end

  @doc section: :control_change
  @doc """
  Creates an data entry message for MSB.

  Used to control the value for NRPN (Non-Registered Parameter Number) or RPN (Registered Parameter Number) parameters.

  Takes a number as it's first parameter, in the range of 0-16383.

  A channel number can be provided as an option.
  """
  def data_entry_msb(value, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    # control_change(7, volume_num, channel: channel)
    <<msb::7, lsb::7>> = <<value::14>>
    msb_binary = control_change(6, msb, channel: channel)
    lsb_binary = control_change(0x26, lsb, channel: channel)
    <<msb_binary::binary, lsb_binary::binary>>
  end

  @doc section: :control_change
  @doc """
  Creates a volume messsage. This was formally called 'Main Volume' in the MIDI 1.0 spec.

  Takes a number as it's first parameter, in the range of 0-127.

  For example, to set to maximum volume:
  ```
  Midiex.Message.volume(127)

  # Returns:
  <<176, 7, 127>>
  ```

  ## 14-bit version
  If you want a high-resolution volume message (e.g. in the range of 0-16383), you can pass the option `high_res: true`, e.g.:
  ```
  Midiex.Message.volume(16383, high_res: true)

  # Returns:
  <<176, 7, 127, 176, 39, 127>>
  ```
  A channel number can be provided as an option.
  """
  def volume(volume_num, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    high_res = Keyword.get(opts, :high_res, false)
    if high_res do
      # High-res (14 bit version)
      <<msb::7, lsb::7>> = <<volume_num::14>>
      msb_binary = control_change(7, msb, channel: channel)
      lsb_binary = control_change(0x27, lsb, channel: channel)
      <<msb_binary::binary, lsb_binary::binary>>
    else
      control_change(7, volume_num, channel: channel)
    end
  end

  @doc section: :control_change
  @doc """
  Controls the left and right balance, generally for stereo patches.

  A value of 64 equals the center.

  Values below 64 moves the sound to the left, and above to the right.

  ## Example
  ```
  Midiex.Message.balance(64)
  ```

  ## 14-bit version
  If you want a high-resolution balance message (e.g. in the range of 0-16383), you can pass the option `high_res: true`, e.g.:
  ```
  # Center channel (high res)
  Midiex.Message.balance(8191, high_res: true)

  # Returns:
  <<176, 8, 63, 176, 40, 127>>
  ```
  """
  def balance(value, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    high_res = Keyword.get(opts, :high_res, false)

    if high_res do
       # High-res (14 bit version)
       <<msb::7, lsb::7>> = <<value::14>>
       msb_binary = control_change(8, msb, channel: channel)
       lsb_binary = control_change(0x28, lsb, channel: channel)
       <<msb_binary::binary, lsb_binary::binary>>
    else
      control_change(8, value, channel: channel)
    end
  end

  @doc section: :control_change
  @doc """
  Change the panoramic (pan) of a channel.

  This shifts the sound from the left or right ear in when playing stereo.

  Values below 64 moves the sound to the left, and above to the right.

  ## Example
  ```
  # Pan to middle
  Midiex.Message.pan(64)
  ```

  ## 14-bit version
  If you want a high-resolution pan message (e.g. in the range of 0-16383), you can pass the option `high_res: true`.
  ```
  # Pan to middle (high res version)
  Midiex.Message.pan(8191, high_res: true)
  ```
  """
  def pan(pan, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    high_res = Keyword.get(opts, :high_res, false)

    if high_res do
      # High-res (14 bit version)
      <<msb::7, lsb::7>> = <<pan::14>>
      msb_binary = control_change(8, msb, channel: channel)
      lsb_binary = control_change(42, lsb, channel: channel)
      <<msb_binary::binary, lsb_binary::binary>>
    else
      control_change(10, pan, channel: channel)
    end
  end

  @doc section: :channel_mode
  @doc """
  Creates an all sound off message. This mutes all sound regardless of release time or sustain.
  """
  def sound_off(opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    control_change(120, 0, channel: channel)
  end

  @doc section: :channel_mode
  @doc """
  Creates an all notes off message. This mutes all sounding notes.

  The release time will still be maintained.

  Notes held by sustain will not turn off until sustain pedal is depressed.
  """
  def all_notes_off(opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    control_change(123, 0, channel: channel)
  end

  @doc section: :channel_mode
  @doc """
  Creates a message that will reset all controllers to their default.
  """
  def reset_controllers(opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    control_change(121, 0 ,channel: channel)
  end

  @doc section: :channel_mode
  @doc """
  Sets Omni mode on or off.

  The first parameter takes one of the following booleans:
  - `true` to switch Omni mode on
  - `false` to swithc Omni mode off
  """
  def omni_mode(true_or_false \\ true, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    case true_or_false do
      true -> control_change(125, 0, channel: channel)
      false -> control_change(124, 0, channel: channel)
    end
  end

  @doc section: :channel_mode
  @doc """
  Creates a message which will set the device to polyphonic mode.

  Takes as it's parameters:
  1. `true` to set poly mode on, or `false` to switch on mono mode (or use `mono_mode`)

  ## Example
  ```
  Midiex.Message.poly_mode()

  # Returns
  <<176, 127, 0>>
  ```
  """
  def poly_mode(true_or_false \\ true, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    case true_or_false do
      true -> control_change(127, 0, channel: channel)
      false -> control_change(126, 0, channel: channel)
    end
  end

  @doc section: :channel_mode
  @doc """
  Creates a message which will set the device to monophonic mode.

  Takes as it's parameters:
  1. `true` to set mono mode on, or `false` to switch on poly mode
  2. the number of channels, or 0 if the number of channels equals the number of voices in the receiver.

  ## Example
  ```
  # Set device to monophonic mode
  Midiex.Message.mono_mode()

  # Returns:
  <<176, 126, 0>>
  ```
  """
  @spec mono_mode(boolean, any, keyword) :: <<_::24>>
  def mono_mode(true_or_false \\ true, number_of_channels \\ 0, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    case true_or_false do
      true -> control_change(126, number_of_channels, channel: channel)
      false -> poly_mode(true, opts)
    end
  end

  @doc section: :channel_mode
  @doc """
  Switches local control on or off by creating a local control message.

  An example of local control is that you may want the synthesizer to be played by means of its own keyboard, therefore setting `Midiex.Message.local_control(true)`.

  If you were controlling it from a PC only, and didn't want it to have local control, you could send the `Midiex.Message.local_control(false)` message.

  More information at: https://electronicmusic.fandom.com/wiki/Local_control
  """
  def local_control(true_or_false \\ true, opts \\ []) do
    channel = Keyword.get(opts, :channel, 0)
    case true_or_false do
      true -> control_change(122, 127, channel: channel)
      false -> control_change(122	, 0, channel: channel)
    end
  end


  @doc section: :system
  @doc """
  Creates a system exclusive message, also known as a SysEx message.

  This function takes the following parameters:
  1. **SysEx ID number**: A code representing the device manufacturer, see the [offical list of manurfacturer IDs](https://www.midi.org/specifications-old/item/manufacturer-id-numbers)
  2. **Data**: series of hex data bytes representing the message body. The hex data bytes values are between 0x00 and 0x7F (0 and 127).

  ## About SysEx
  SysEx messages can contain any number of hexadecimal bytes. They the message data is specific to each manufacturers device and include the manufacturer's identification code.

  SysEx messages are wrapped in a start (0xF0) and end (0xF7) byte, e.g.:

  ```<<0xF0, id_number, data, 0xF7>>```

  ## Example
  ```
  # Send data to a Roland device
  # Roland uses the ID of 0x41 (or you can pass the integer of 65)
  Midiex.Message.sysex(0x41, <<0x01, 0x34>>)

  # Returns <<240, 65, 1, 52, 247>>

  # You can pass integer values instead
  Midiex.Message.sysex(65, <<1, 52>>)

  # Returns <<240, 65, 1, 52, 247>>
  ```
  """
  def sysex(id_number, data) do
    <<0xF0, id_number>> <> data <> <<0xF7>>
  end

  @doc section: :system
  @doc """
  Creates a MIDI quarter frame message, used to send timing information.

  Takes a single byte as the first parameter.

  Timing information is in the [MIDI time code](https://en.wikipedia.org/wiki/MIDI_timecode) format, which is hours:minutes:seconds:frames. This follows the same timing information as standard [SMPTE timecode](https://en.wikipedia.org/wiki/SMPTE_timecode).

  As MIDI send values in the range of 0-127, a single  byte cannot carry the full time. For this reason, 8 quarter frame messages must be sent to piece together the current MIDI time.

  The `timecode/1` function will automatically convert a hours:minutes:seconds:frames timecode string create the individual quarter frames.
  """
  def quarter_frame(data), do: <<0xF1, data>>

  @doc section: :system
  @doc """
  Creates a eight MIDI quarter frame messages to represent a single hours:minutes:seconds:frames timecode string.

  ## Example
  ```
  Midiex.Message.timecode("01:00:00:00")

  # Returns
  # <<241, 0, 241, 16, 241, 32, 241, 48, 241, 64, 241, 80, 241, 97, 241, 112>>
  ```
  """

  def timecode(timecode_string) when is_binary(timecode_string) do
    %{"frame" => frame, "hour" => hour, "minute" => minute, "second" => second} =
      Regex.named_captures(~r/(?<hour>\d\d)[:](?<minute>\d\d)[:](?<second>\d\d)[:](?<frame>\d\d)/i, timecode_string)

      {frame_msb, frame_lsb}    = String.to_integer(frame)  |> to_nibble()
      {hour_msb, hour_lsb}      = String.to_integer(hour)   |> to_nibble()
      {minute_msb, minute_lsb}  = String.to_integer(minute) |> to_nibble()
      {second_msb, second_lsb}  = String.to_integer(second) |> to_nibble()

      [
        (0 <<< 4) + frame_lsb,
        (1 <<< 4) + frame_msb,
        (2 <<< 4) + second_lsb,
        (3 <<< 4) + second_msb,
        (4 <<< 4) + minute_lsb,
        (5 <<< 4) + minute_msb,
        (6 <<< 4) + hour_lsb,
        (7 <<< 4) + hour_msb
      ]
      |> Enum.map(fn time_data -> quarter_frame(time_data) end)
      |> Enum.join(<<>>)
  end

  defp to_nibble(value) do
    {value >>> 4, band(value, 0b00001111)}
  end


  @doc section: :system
  @doc """
  Creates a MIDI clock message, used for clock synchronization.

  The MIDI clock message is a timing message that is sent at regular intervals to tell the listening devices where it is in terms of time.
  """
  def clock, do: <<0xF8>>

  @doc section: :system
  @doc """
  Creates a MIDI start message.

  Used to tell listening devices to commence playback of the current MIDI sequence.
  """
  def start(), do: <<0xFA>>

  @doc section: :system
  @doc """
  Creates a MIDI continue message.

  Used to tell listening devices to resume playback of the current MIDI sequence.
  """
  def resume(), do: <<0xFB>>

  @doc section: :system
  @doc """
  Creates a MIDI stop message.

  Used to tell listening devices to stop playing the current MIDI sequence.
  """
  def stop(), do: <<0xFC>>


  @doc section: :system
  @doc """
  Creates a MIDI active sense message.

  Used to tell listening devices that the MIDI connection is still active.
  """
  def active_sense(), do: <<0xFE>>

  @doc section: :system
  @doc """
  Creates a MIDI reset message.

  Various MIDI devices will interpret this message differently. Often it will cause a device to stop playing and set the song position to the beginning.

  The MIDI 1.0 specification says the following should occur when a reset message is sent:
  - The modulation wheel, hold pedal, portamento pedal, sostenuto pedal and soft pedal are set to 0
  - The pitch wheel is set to center which is usually 64, but could be set to 0
  - The channel pressure and the key pressure are set to 0
  - Registered and nonregistered parameter numbers (98 to 101) are set to 127
  - Expression is set to 127.
  """
  def reset(), do: <<0xFF>>

end
