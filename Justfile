# Justfile
set shell := ["zsh", "-c"]

default:
    @just --list

# Initialize your Mac host with required native tooling
init:
    @echo "==> Preparing target architectures..."
    rustup target add x86_64-apple-darwin aarch64-apple-darwin
    rustup target add x86_64-pc-windows-msvc x86_64-pc-windows-gnu
    rustup target add x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu
    @echo "==> Installing host helper utilities..."
    cargo install cross --git https://github.com/cross-rs/cross
    cargo install cargo-xwin
    brew install mingw-w64 docker-buildx docker-credential-helper
    @echo "==> Configuring Docker CLI plugins..."
    mkdir -p ~/.docker/cli-plugins
    ln -sfn $(which docker-buildx) ~/.docker/cli-plugins/docker-buildx

# Start Colima engine
up:
    @echo "==> Starting Colima with Virtualisation.framework..."
    colima start --cpu 4 --memory 8 --disk 64 --vm-type=vz --vz-rosetta

# Stop Colima engine
down:
    @echo "==> Shutting down Colima..."
    colima stop

# Fast check to ensure no syntax errors before running heavy builds
check-rust:
    @echo "==> Validating Rust code..."
    cd native/midiex && cargo check

test-elixir:
    @echo "==> Testing Elixir codebase..."
    mix deps.get
    mix test

# Natively build macOS binaries
build-mac:
    @echo "==> Compiling Apple Darwin NIFs..."
    cd native/midiex && cargo build --target aarch64-apple-darwin --release
    cd native/midiex && cargo build --target x86_64-apple-darwin --release

# Natively build Windows binaries container-free
build-windows:
    @echo "==> Compiling Windows NIFs..."
    cd native/midiex && cargo xwin build --target x86_64-pc-windows-msvc --release
    cd native/midiex && cargo build --target x86_64-pc-windows-gnu --release

# Build Linux matrices inside Colima using modern buildx
build-linux:
    @echo "==> Compiling Linux & RISC-V NIFs inside Colima..."
    export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"; \
    export PKG_CONFIG_ALLOW_CROSS="1"; \
    cd native/midiex && \
    cross build --target x86_64-unknown-linux-gnu --release && \
    cross build --target aarch64-unknown-linux-gnu --release && \
    cross build --target x86_64-unknown-linux-musl --release && \
    cross build --target aarch64-unknown-linux-musl --release && \
    cross build --target riscv64gc-unknown-linux-gnu --release

# The full execution sequence
ci: check-rust test-elixir build-mac build-windows build-linux
    @echo "🎉 All local CI steps successfully executed!"
