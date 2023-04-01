defmodule Midiex.Time do

  @one_minute_in_ms 60_000
  @one_second_in_ms 1_000
  @one_minute_in_ms 60 * @one_second_in_ms

  def bpm_to_ms(bpm), do: @one_minute_in_ms / bpm

  def ms_to_bpm(ms), do: @one_minute_in_ms / ms

end
