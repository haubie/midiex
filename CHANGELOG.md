# Changelog

## 0.6.4 (2026-06-09) - includes a breaking changes
This release:
- **[Breaking change]** Modifies the Rust code to return MIDI data in binary format (e.g. `<<153, 60, 70>>`), rather than a list (e.g. `[153, 60, 70]`). See [issue #10](https://github.com/haubie/midiex/issues/10) for more information. Thank you to [@Rashidwi](https://github.com/Rashidwi) and [@nseaSeb](https://github.com/nseaSeb) for raising it. If you'd prefer the old behavior, you can use `:binary.bin_to_list/1` to convert the binary data back to a list, e.g.:
```elixir
binary = <<153, 60, 70>>
list = :binary.bin_to_list(binary)
#=> [153, 60, 70]
```
- **[Breaking change]** Unifies the subscription API for virtual inputs. Subscribing to a `%Midiex.VirtualMidiPort{}` now returns a `%Midiex.MidiMessage{}` struct rather than a raw byte list.
- **Polymorphic port structs**: the `port` field inside `%Midiex.MidiMessage{}` is now polymorphic and type-safe. It will contain either a `%Midiex.MidiPort{}` (for physical/OS device ports) or a `%Midiex.VirtualMidiPort{}` (for custom virtual inputs). This allows for clean, idiomatic pattern matching in your Elixir handlers:
```elixir
# Handle messages from physical keyboard
def handle_msg(%MidiMessage{port: %Midiex.MidiPort{name: "KeyStep Pro"}, data: data}) do
  ...
end

# Handle messages from your custom virtual synth
def handle_msg(%MidiMessage{port: %Midiex.VirtualMidiPort{name: "MyInstrument"}, data: data}) do
  ...
end

```
- Fixes a bug when using `Midiex.Message` functions with the `channel:` option.
- Upgrades to Rustler v0.38.

Additionally:
- Windows ARM based precompiled binary `aarch64-pc-windows-msvc` has been added.
- Mix test suite has been expanded.
- Local build support is available via a `Justfile`.

## 0.6.3 (2024-09-11)
This release is just a refresh of the checksums for the precompiled binaries.

## 0.6.2 (2024-08-11)
This release includes a simple patch for high CPU load. Contributed by [@crop2000](https://github.com/crop2000).
