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
- Windows ARM based:
    - aarch64-pc-windows-msvc

For the above platforms, you do not need Rust's build tools installed as Rustler will automatically download the correct precompiled NIF archive for your architecture.

### Forcing compilation
Should you wish to manually build your own copy of Midiex's Rust-based NIF on a supported platform, you can force local compilation by setting the environment variable `MIDIEX_BUILD` to `true` or `1`:

```bash
export MIDIEX_BUILD=true
```
You'll need to have the Rust build toolchain installed (see below).

# Building Midiex
In most cases, the standard Rust build toolchain is all you need. That being said there may be additional packages that need to be installed on Linux distributions related to ALSA (Advanced Linux Sound Architecture) as well as compilation in general (pkg-config).

## 1. Prerequisites
### Host Rust toolchain
Currently you will need to have Rust's build tools installed on the device you're compiling on. If you're new to Rust, using the [Rust up](https://www.rust-lang.org/tools/install) tool from the offical Rust website or at [rustup.rs](https://rustup.rs/) will be your quickest and simplest way to get it installed.

### Linux system dependencies
If you are compiling natively on a Linux distribution (tested on Ubuntu 22.04+), you will need the development headers for ALSA (Advanced Linux Sound Architecture) and pkg-config.

If using the apt package manager, you can install those via the terminal prompt with:

```bash
sudo apt update && sudo apt install libasound2-dev pkg-config build-essential
```

## 2. Standard local build
Once prerequisites are handled, fetch your Elixir dependencies and run the tests. Mix will automatically compile the native code:
```bash
mix deps.get
mix test
```

## Full CI matrix using `just`
For developers wishing to cross-compile the entire multi-platform matrix (macOS, Linux, Windows, RISC-V) completely locally, the repository provides a automation pipeline orchestrated via `just` and a lightweight container runner (`colima`).

### 1. Additional cross-compilation prerequisites
If you are running on macOS, install the required toolchains, runtimes and Docker plugins:

```bash
# Install task runner, container runtime, and required plugins
brew install just colima docker mingw-w64 docker-buildx docker-credential-helper

# Register the buildx plugin with the Docker CLI
mkdir -p ~/.docker/cli-plugins
ln -sfn $(which docker-buildx) ~/.docker/cli-plugins/docker-buildx

# Install Rust cross-compilation engines
cargo install cross --git [https://github.com/cross-rs/cross](https://github.com/cross-rs/cross)
cargo install cargo-xwin
```

### 2. Available pipeline commands
You can orchestrate the full local pipeline using the following just commands from the project root:
| Command | Action Performed |
|------- | --------------- |
| `just init` | One-time setup to download required target architectures to your local toolchain. |
| `just up` | Spins up the lightweight Linux engine (colima) optimized for Apple Silicon virtualisation. |
| `just ci` | Executes the full pipeline: Rust safety checks, Elixir tests, native Mac/Windows builds, and dynamic Linux/RISC-V matrix builds inside the containers. |
| `just down` | Shuts down the container engine to conserve your system memory and battery life. |

#### Example local workflow execution:
```bash
just init
just up
just ci
just down
```

### Troubleshooting credential store errors (Mac)
If you previously had the official Docker desktop application installed on your Mac, running `just ci` might throw a metadata resolution error resembling:
`error getting credentials - err: exec: "docker-credential-desktop": executable file not found in $PATH`

Because this local pipeline uses a lightweight container engine (`colima`) instead of the heavier Docker desktop application, you must update your global Docker config file to point to your Mac's native keychain architecture. 

Open `~/.docker/config.json` and change the `credsStore` line from `"desktop"` to `"osxkeychain"`:

```json
{
  "auths": {},
  "credsStore": "osxkeychain",
  "currentContext": "colima"
}
