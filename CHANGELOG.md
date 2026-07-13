# Changelog

## 0.6.4 (2026-06-09) - includes a breaking change
This release:
- modifies the Rust code to return MIDI data in binary format (e.g. `<<153, 60, 70>>`), rather than a list (e.g. `[153, 60, 70]`). **Note this is a breaking change.** See [issue #10](https://github.com/haubie/midiex/issues/10) for more information. Thank you to [@Rashidwi](https://github.com/Rashidwi) and [@nseaSeb](https://github.com/nseaSeb) for raising it. If you'd prefer the old behavior, you can use `:binary.bin_to_list/1` to convert the binary data back to a list, e.g.:
```elixir
binary = <<153, 60, 70>>
list = :binary.bin_to_list(binary)
#=> [153, 60, 70]
```
- fixes a bug when using `Midiex.Message` functions with the `channel:` option.
- upgrades to Rustler v0.38.

## 0.6.3 (2024-09-11)
This release is just a refresh of the checksums for the precompiled binaries.

## 0.6.2 (2024-08-11)
This release includes a simple patch for high CPU load. Contributed by [@crop2000](https://github.com/crop2000).
