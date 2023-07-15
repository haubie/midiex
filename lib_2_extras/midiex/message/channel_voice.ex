defmodule Midiex.Message.ChannelVoice do
  @moduledoc """
  Represents a MIDI Channel Voice Message.

  The majority of MIDI messages transmitted are Channel Voice Messages. They include:

  - note_on
  - note_off
  - channel_aftertouch
  - polyphonic_aftertouch
  - pitch_bend
  - program_change
  - control_change
  """
  defstruct [status: nil, channel: 0, msb: 0, lsb: 0, value: nil]

  @stats_codes [
    note_on: 0x9,
    note_off: 0x8,
    polyphonic_aftertouch: 0xA,
    channel_aftertouch: 0xD,
    control_change: 0xB,
    program_change: 0xC,
    pitch_bend: 0xE
  ]


  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  def note_on(note, velocity, opts \\ []) do
    new(status: :note_on, msb: note, value: velocity, channel: get_channel(opts))
  end

  def to_binary(msg) when is_struct(msg, __MODULE__) do
    <<get_status_code(msg.status)::4, msg.channel::4, msg.msb, msg.value>>
  end

  def from_binary(bin_msg) when is_binary(bin_msg) do
    <<status_code::4, channel::4, msb::7, value::7>> = bin_msg
    new(status: to_status_atom(status_code), channel: channel, msb: msb, value: value)
  end

  defp get_status_code(status), do: Keyword.get(@stats_codes, status)
  defp to_status_atom(status_code), do: Keyword.filter(@stats_codes, fn {_k,v} -> v == status_code end)

  defp get_channel(opts), do: Keyword.get(opts, :channel, 0)
end
