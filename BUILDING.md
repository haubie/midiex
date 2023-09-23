![Midiex](assets/midiex_logo_wide.png)

[![Documentation](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/midiex)
[![Package](https://img.shields.io/hexpm/v/supercollider.svg)](https://hex.pm/packages/midiex)

## Precompiled binaries
Since v0.6, Midiex uses [Rustler Precompiled](https://dashbit.co/blog/rustler-precompiled) to provide precompiled binaries on the following platforms:

- Apple Mac:
    - M-series: aarch64-apple-darwin
    - x86-series: x86_64-apple-darwin
- Linux x86 based:
    - x86_64-unknown-linux-gnu
    - x86_64-unknown-linux-musl
- Linux ARM based:
    - aarch64-unknown-linux-gnu
    - aarch64-unknown-linux-musl
- Linux RISC-V based:
    - riscv64gc-unknown-linux-gnu
- Windows x86 based:
    - x86_64-pc-windows-msvc
    - x86_64-pc-windows-gnu

For the above platforms you should not need Rust's build tools as Rustler will download Midiex's precompiled NIF for the correct platform.

### Forcing compilation
Should you wish to build your own binary of Midiex's Rust-based NIF on the above platforms, you can force that by setting the environmental `MIDIEX_BUILD` to `true` or `1`, e.g.:

```
export MIDIEX_BUILD=true
```
You'll need to have the Rust build toolchain installed (see below).

# Building Midiex
In most cases, the standard Rust build toolchain is all you need. That being said there may be additional packages that need to be installed on Linux distributions related to ALSA (Advanced Linux Sound Architecture) as well as compilation in general (pkg-config).

## Rust build tools
Currently you will need to have Rust's build tools installed on the device you're compiling on. If you're new to Rust, using the [Rust up](https://www.rust-lang.org/tools/install) tool from the offical Rust website or at [rustup.rs](https://rustup.rs/) will be your quickest and simplest way to get it installed.

## Linux
Additionally on Linux (currently tested on Ubuntu 22.04), you may need some additional packages installed such as libasound2-dev and pkg-config.

If using the apt package manager, you can install those via the terminal prompt with:

```sudo apt install libasound2-dev pkg-config.```