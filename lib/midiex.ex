defmodule Midiex do
  @moduledoc """
  Documentation for `Midiex`.
  """
  alias Midiex.Backend
  alias Midiex.Note
  alias Midiex.Chord
  alias Midiex.Scale

  # ##########
  # NATIVE API
  # ##########

  # MIDI port functions

  @doc """
  Lists MIDI ports availabile on the system.

  ```
  Midiex.list_ports()

  # Returns a list of input or output ports:

  # [
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "Piano",
  #     num: 0,
  #     port_ref: #Reference<0.249304305.242352152.40090>
  #   },
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "Drums",
  #     num: 1,
  #     port_ref: #Reference<0.249304305.242352152.40091>
  #   }
  # ]
  ```
  """
  def list_ports(), do: Backend.list_ports()

  @doc """
  List MIDI ports matching the specified direction (e.g. input or output)

  Takes an atom as the first parameter representing the direction:
  - :input - lists input ports only
  - :output - lists output ports only.

  ```
  Midiex.list_ports(:input)

  # Returns a list of input or output MIDI ports:

  # [
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "Piano",
  #     num: 0,
  #     port_ref: #Reference<0.249304305.242352152.40090>
  #   },
  #   %Midiex.MidiPort{
  #     direction: :input,
  #     name: "Drums",
  #     num: 1,
  #     port_ref: #Reference<0.249304305.242352152.40091>
  #   }
  # ]
  ```
  """
  def list_ports(direction) when is_atom(direction), do: filter_port_direction(list_ports(), direction)

  @doc """
  Lists MIDI ports containing the name. Optionally takes a direction (:input or :output) can be given.

  Examples:
  ```
  # List ports with the name 'Arturia'
  Midiex.list_ports("Arturia")

  # List input ports with the name 'Arturia'
  Midiex.list_ports("Arturia", :input)

  # List output ports with the name 'Arturia'
  Midiex.list_ports("Arturia", :output)
  ```
  """
  def list_ports(name, direction \\ nil) when is_binary(name) do
    filter_port_name_contains(list_ports(), name, direction: direction)
  end

  @doc """
  Returns the count of the number of input and output MIDI ports in as a map.

  ```
  Midiex.count_ports()

  # Returns a map in the following format:
  # %{input: 2, output: 0}
  ```
  """
  def count_ports(), do: Backend.count_ports()

  @doc """
  Creates a connection to the MIDI port.

  ```
  # get the first available output port
  out_port = Midiex.list_ports(:output) |> List.first()
  out_conn = Midiex.connect(out_port)
  ```
  """
  def connect(midi_port), do: Backend.connect(midi_port)

  @doc """
  Closes a MIDI output connection.

  ```
  Midiex.close_out_conn(out_conn)
  ```
  """
  def close_out_conn(out_conn), do: Backend.close_out_conn(out_conn)

  @doc """
  Creates a virtual output connection.

  This allows your Elixir application to be seen as a MIDI device.

  ```
  # Create an output connection called "piano"
  piano_conn = Midiex.create_virtual_output_conn("piano")
  ```

  You can send messages to MIDI software or hardware connected to this virtual device in the standard way, e.g.:
  ```
  note_on = <<0x90, 60, 127>>
  note_off = <<0x80, 60, 127>>

  Midiex.send_msg(piano, note_on)
  :timer.sleep(3000) # wait three seconds
  Midiex.send_msg(piano, note_off)
  ```
  """
  def create_virtual_output_conn(name), do: Backend.create_virtual_output_conn(name)

  # MIDI messaging functions

  @doc """
  Sends a binary MIDI message to a specified output connection.

  Takes the following parameters:
  - Output connection: which is an %Midiex.OutConn{} struct
  - MIDI message: which is in a binary format, such as <<0x90, 60, 127>>
  """
  def send_msg(out_port_conn, midi_msg), do: Backend.send_msg(out_port_conn, midi_msg)

  # Midiex callback functions
  def subscribe(), do: Backend.subscribe()
  def listen(input_port), do: Backend.listen(input_port)

  # #######
  # HELPERS
  # #######

  defp filter_port_name_contains(ports_list, name, opts \\ []) do
    direction = Keyword.get(opts, :direction, nil)
    ports_list
    |> Enum.filter(fn port -> String.contains?(port.name, name) end)
    |> filter_port_direction(direction)
  end

  defp filter_port_direction(ports_list, nil), do: ports_list

  defp filter_port_direction(ports_list, direction) do
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
