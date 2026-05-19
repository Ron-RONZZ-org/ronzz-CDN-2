#!/usr/bin/env bash
set -euo pipefail

# Alacritty installer for Linux Mint 22.x (Ubuntu 24.04 base)
# Installs build deps, builds from source, installs system-wide, and sets up terminfo.

if [[ $EUID -eq 0 ]]; then
  echo "Please run this script as a regular user (it will use sudo when needed)." >&2
  exit 1
fi

echo "==> Updating package lists"
sudo apt update

echo "==> Installing build dependencies"
sudo apt install -y \
  git \
  curl \
  cmake \
  g++ \
  pkg-config \
  libfontconfig1-dev \
  libxcb-xfixes0-dev \
  libxkbcommon-dev \
  python3 \
  scdoc \
  gzip \
  desktop-file-utils

echo "==> Installing Rust via rustup if needed"
if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  source "$HOME/.cargo/env" || true
fi

echo "==> Ensuring stable toolchain"
rustup override set stable
rustup update stable

echo "==> Cloning Alacritty"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
git clone https://github.com/alacritty/alacritty.git "$WORKDIR/alacritty"
cd "$WORKDIR/alacritty"

echo "==> Building Alacritty"
cargo build --release

echo "==> Installing binary"
sudo install -Dm755 target/release/alacritty /usr/local/bin/alacritty

echo "==> Installing terminfo"
sudo tic -xe alacritty,alacritty-direct extra/alacritty.info

echo "==> Installing desktop entry and icon"
sudo install -Dm644 extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
sudo desktop-file-install \
  --dir=/usr/share/applications \
  extra/linux/Alacritty.desktop

sudo update-desktop-database

echo "==> Installing shell completions (optional)"
mkdir -p "$HOME/.bash_completion"
cp extra/completions/alacritty.bash "$HOME/.bash_completion/alacritty"
if ! grep -q 'source ~/.bash_completion/alacritty' "$HOME/.bashrc" 2>/dev/null; then
  echo 'source ~/.bash_completion/alacritty' >> "$HOME/.bashrc"
fi

echo
echo "Done."
echo "You may need to restart your shell or run: source ~/.bashrc"
echo "Launch Alacritty with: alacritty"
