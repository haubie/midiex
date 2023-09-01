![Midiex](assets/midiex_logo_wide.png)

[![Documentation](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/midiex)
[![Package](https://img.shields.io/hexpm/v/supercollider.svg)](https://hex.pm/packages/midiex)

# Building Midiex
In most cases, the standard Rust build toolchain is all you need. That being said there may be additional packages that need to be installed on Linux distributions related to ALSA (Advanced Linux Sound Architecture) as well as compilation in general (pkg-config).

## Rust build tools
Currently you will need to have Rust's build tools installed on the device you're compiling on. If you're new to Rust, using the [Rust up](https://www.rust-lang.org/tools/install) tool from the offical Rust website or at [rustup.rs](https://rustup.rs/) will be your quickest and simplest way to get it installed.

## Linux
Additionally on Linux (currently tested on Ubuntu 22.04), you may need some additional packages installed such as libasound2-dev and pkg-config.

If using the apt package manager, you can install those via the terminal prompt with:

```sudo apt install libasound2-dev pkg-config.```

## Future - precompiled binaries
It is a goal of this project to migrate to [Rustler Precompiled](https://dashbit.co/blog/rustler-precompiled) so that the rust build tools don't have to be installed and the precompiled binaries of the Midiex's Rust-based NIF is downloaded for the correct platform.










