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

If using the apt package manager, you can install those via the terminal:

```bash
sudo apt update && sudo apt install libasound2-dev pkg-config build-essential
```

## 2. Standard local build
Once prerequisites are handled, fetch your Elixir dependencies and run the tests. Mix will automatically compile the native code:
```bash
mix deps.get
mix test
```

## Advanced: Replicating the full CI matrix with `just`
For developers wishing to cross-compile the entire multi-platform matrix (macOS, Linux, Windows, RISC-V) completely locally, the repository provides an automation pipeline orchestrated via `just` and a lightweight container runner (`colima`).

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
| `just test-linux` | Builds the local `midiex-test` Docker image and executes the full Elixir & Rust test suite natively on Linux. |
| `just ci` | Executes the full pipeline: Rust safety checks, Elixir tests, native Mac/Windows builds, and dynamic Linux/RISC-V matrix builds inside the containers. |
| `just down` | Shuts down the container engine to conserve your system memory and battery life. |

#### Example local workflow execution:
```bash
just init
just up
just ci
just down
```

## Local Linux testing via Docker/Colima (`just test-linux`)
If you want to run the Linux test suite locally you can execute:

```bash
just up
just test-linux
```
This compiles your native Rust NIF code from scratch natively inside a container and runs Elixir's ExUnit suite on Linux.

### How it works under the hood:
- **Prerequisites**: It uses the local `Dockerfile.test` which pulls the official Elixir 1.18 base image, installs native compilers (`gcc`, `pkg-config`), ALSA header files (`libasound2-dev`), and the standard Rust compiler.
- **Network routing**: The `Justfile` recipe builds the image utilizing the `--network=host` flag, which cleanly routes DNS queries through your host Mac and avoids virtual machine DNS resolution hiccups.
- **Dynamic device support**: The test container is launched in `--privileged` mode to bridge virtual device channels. If your VM kernel possesses active MIDI sound driver modules, the virtual loopback tests will execute.
- **Graceful fallbacks**: If the Linux VM's kernel lacks active ALSA sound sequencer devices (specifically `/dev/snd/seq`), our `test/test_helper.exs` dynamically detects this and automatically excludes the `@tag :virtual_ports` tests. The standard API, converter, and message-builder tests will still execute and pass, keeping the suite green.

## Maintainer architecture notes (`Cross.toml` file rationale)
Cross-compiling C-dependent libraries like ALSA (`libasound`) and Udev (`libudev`) across multiple distinct C standard library runtimes introduces structural challenges. Below is the technical rationale for how the isolated `Cross.toml` targets are configured.

### 1. RISC-V 64 GNU target
The standard Ubuntu package registry mirrors do not serve RISC-V headers to standard x86/ARM environments by default.

**Implementation:** The pre-build hook explicitly generates a custom package routing source (`/etc/apt/sources.list.d/riscv64.list`) mapping to `ports.ubuntu.com` before invoking `apt-get update`. This allows the container's multi-arch environment to discover and resolve `libasound2-dev:riscv64`.

### 2. MUSL targets (x86_64 and aarch64)
Standard Linux package managers compile system audio packages dynamically linked against **GLIBC**. Forcing a **MUSL** target to link against GLIBC system packages corrupts the target runtime environment and throws linker compatibility panics.

**Implementation:** To achieve a true, high-fidelity static build, the MUSL target profiles bypass apt audio packages entirely. The hooks download clean upstream alsa-lib source code and compile it directly inside the container utilising the native target MUSL compiler layout.

**Compilation flags required:**
* `CFLAGS="-fPIC" --with-pic`: Forces the static library archive (`libasound.a`) to generate Position Independent Code. This is mandatory because the final output artifact loaded by Elixir's Rustler layer is a dynamically shifted shared object file (`.so`).
* `--with-versioned=no`: Disables GNU symbol versioning. Stripping version nodes prevents the dynamic linker from panicking when resolving core symbols inside a fully static environment.

### Upgrading the static `alsa-lib` version
If you ever need to upgrade the version of `alsa-lib` used by the MUSL targets to patch vulnerabilities or access newer features:

1. Visit the official [ALSA Project Release page](https://www.alsa-project.org/wiki/Main_Page_News) to identify the latest stable version (e.g. `1.2.16`).
2. Open `Cross.toml` and locate the `[target.x86_64-unknown-linux-musl]` and `[target.aarch64-unknown-linux-musl]` blocks.
3. In both blocks, update the three instances of the version string inside the `pre-build` array:
   * The download link (`.../alsa-lib-X.X.XX.tar.bz2`)
   * The extraction path (`tar -xf alsa-lib-X.X.XX.tar.bz2`)
   * The directory navigation (`cd alsa-lib-X.X.XX`)
4. **CRITICAL:** When swapping versions, you must preserve the exact placement parameters: `CFLAGS="-fPIC"`, `--with-pic`, and `--with-versioned=no`. Without these, the resulting dynamic Elixir NIF wrapper will encounter critical linkage faults.

## Troubleshooting
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
```
Alternatively, if you are exclusively pulling public target compilation images anonymously, you can safely remove the "credsStore" property entirely.
