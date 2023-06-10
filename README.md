![Midiex](assets/midiex_logo_wide.png)

[![Documentation](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/midiex)
[![Package](https://img.shields.io/hexpm/v/supercollider.svg)](https://hex.pm/packages/midiex)

# Midiex overview
Midiex is a cross-platform, real-time MIDI processing in Elixir library.

## midir Rust library
Using [Rustler](https://github.com/rusterlium/rustler), Midiex wraps the excellent [midir](https://github.com/Boddlnagg/midir) Rust library.

Midir support a range of platforms and backends, such as:

- ALSA (Linux)
- WinMM (Windows)
- CoreMIDI (MacOS, iOS)
- WinRT (Windows 8+), 
- Jack (Linux, macOS), 

Using WinRT or Jack requires special feature flags enabled. See the [midir GitHub](https://github.com/Boddlnagg/midir) and [create docs](https://docs.rs/crate/midir/latest) for more details.

## Status
This library is currently under active development and it’s API is likely to change. It's been tested on MacOS only.

## API
At it's most basic level, the core functions of Midiex are for:
- **listing** or **counting** MIDI ports availble (for example, a keyboard or synth)
- **creating** or **closing connections** to MIDI ports
- **sending** or **receiving messages** to and from connections
- **creating a virtual output connection** so your Elixir application appears as a MIDI device.

## MIDI messages
MIDI messages are in binary format. They're usually in the format of one status byte followed by one or two data bytes.

For example, the status byte for 'Note On' is `0x90` in HEX format. The data byte representing the note Middle C is `60`. The data byte representing velocity (i.e. how hard the key was struck when the note was played) is an integer in the range `0 - 127` where 127 is the loudest.

Putting that together, the message to play Middle C at a velocity of 127 is: `<<0x90, 60, 127>>`
You can stop the same note from playing by sending the 'Note Off' status byte `0x80`, which would make the message: `<<0x80, 60, 127>>`.

For more information on MIDI messages, see the offical (MIDI Assocations Specifications)[https://www.midi.org/specifications], [Expanded MIDI 1.0 message list](https://www.midi.org/specifications-old/item/table-2-expanded-messages-list-status-bytes) or the various articles online such as (this one)[https://www.songstuff.com/recording/article/midi_message_format/].

## Example
```
# List MIDI ports
Midiex.list_ports()

# Create a virtual output connection
piano = Midiex.create_virtual_output_conn("piano")

# Returns an output connection:
# %Midiex.OutConn{
#   conn_ref: #Reference<0.1633267383.3718381569.210768>,
#   name: "piano",
#   port_num: 0
# }

# Send to MIDI messages to a connection
note_on = <<0x90, 60, 127>>
note_off = <<0x80, 60, 127>>

Midiex.send_msg(piano, note_on)
:timer.sleep(3000) # wait three seconds
Midiex.send_msg(piano, note_off)

```
## Getting started

### Adding it to your Elixir project (coming soon)
The package can be installed by adding supercollider to your list of dependencies in mix.exs:
```
def deps do
  [
    {:midiex, "~> 0.1.0"}
  ]
End
```elixir

### Using within LiveBook and IEx
```
Mix.install([{:midiex, "~> 0.1.0"}])
```elixir

#### LiveBook tour
Also see the introductory tour in LiveBook at [/livebook/midiex_notebook.livemd](https://github.com/haubie/midiex/blob/main/livebook/midiex_notebook.livemd).

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fhaubie%2Fmidiex%2Fblob%2Fmain%2Flivebook%2Fmidiex_notebook.livemd)

## Documentation
The docs can be found at https://hexdocs.pm/midiex.



