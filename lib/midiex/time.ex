defmodule Midiex.Time do

  @default_bpm 60
  @one_minute_in_ms 60_000
  @one_second_in_ms 1_000
  @one_minute_in_ms 60 * @one_second_in_ms

  @doc """
  Use
  """
  def set_tempo(bpm \\ @default_bpm) do
    :persistent_term.put("midiex_beat_duration", bpm_to_ms(bpm))
  end

  def get_tempo(), do: :persistent_term.get("midiex_beat_duration")

  def wait(beats \\ 1), do: (Midiex.Time.get_tempo() * beats) |> round() |> :timer.sleep()

  def bpm_to_ms(bpm), do: @one_minute_in_ms / bpm

  def ms_to_bpm(ms), do: @one_minute_in_ms / ms

end
