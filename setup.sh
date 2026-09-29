#!/usr/bin/env bash
# Install Neovim and the tools this config needs, then register Bash aliases.
# Works on Linux (apt, dnf, pacman, zypper, apk) and macOS (Homebrew), with or
# without sudo. Without root, Neovim installs into ~/.local.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
VERSION="${NVIM_VERSION:-0.11.4}"
OS="$(uname -s)"

SUDO=()
if [[ $EUID -ne 0 ]]; then
  if command -v sudo >/dev/null && sudo -v 2>/dev/null; then SUDO=(sudo); else SUDO=(none); fi
fi
can_root() { [[ ${SUDO[0]:-} != none ]]; }
as_root() { if [[ ${#SUDO[@]} -eq 0 ]]; then "$@"; else "${SUDO[@]}" "$@"; fi; }

# git/curl/tar/cc/make: plugins and Treesitter parsers. ripgrep: file search.
# unzip, Node/npm, Python venv: Mason language servers and formatters.
install_packages() {
  if [[ $OS == Darwin ]]; then
    command -v brew >/dev/null || { echo 'Install Homebrew first: https://brew.sh' >&2; return 1; }
    brew install git curl ripgrep jq unzip node python neovim
  elif ! can_root; then
    echo 'No sudo: skipping system packages. Make sure the tools listed below exist.' >&2
  elif command -v apt-get >/dev/null; then
    as_root apt-get update
    as_root apt-get install -y curl ca-certificates tar gzip unzip git build-essential ripgrep jq \
      nodejs npm python3 python3-venv python3-pip
  elif command -v dnf >/dev/null; then
    as_root dnf install -y curl tar gzip unzip git gcc make ripgrep jq nodejs npm python3 python3-pip
  elif command -v pacman >/dev/null; then
    as_root pacman -Sy --needed --noconfirm curl tar gzip unzip git base-devel ripgrep jq nodejs npm python python-pip
  elif command -v zypper >/dev/null; then
    as_root zypper install -y curl tar gzip unzip git gcc make ripgrep jq nodejs npm python3 python3-pip
  elif command -v apk >/dev/null; then
    as_root apk add curl tar gzip unzip git build-base ripgrep jq nodejs npm python3 py3-pip
  else
    echo 'Unknown package manager: install the tools listed below yourself.' >&2
  fi
}

version_ok() { # Is the nvim on PATH at least $VERSION?
  command -v nvim >/dev/null || return 1
  local have
  have=$(nvim --version | head -n1 | sed -E 's/^NVIM v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
  [[ "$(printf '%s\n%s\n' "$VERSION" "$have" | sort -V | head -n1)" == "$VERSION" ]]
}

install_neovim_linux() {
  local arch
  case "$(uname -m)" in
    x86_64) arch=x86_64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo 'Unsupported architecture; install Neovim yourself.' >&2; return 1 ;;
  esac
  local prefix bindir
  if can_root; then prefix=/opt; bindir=/usr/local/bin; else prefix="$HOME/.local/opt"; bindir="$HOME/.local/bin"; fi
  local dest="$prefix/nvim-linux-$arch" link="$bindir/nvim"
  if [[ -e "$link" && ! -L "$link" ]]; then
    echo "$link is not a symlink. Move it aside before installing." >&2
    return 1
  fi
  TMP=$(mktemp -d)
  trap 'rm -rf -- "$TMP"' EXIT
  local tmp=$TMP
  local archive="nvim-linux-$arch.tar.gz"
  curl --fail --location --retry 3 --output "$tmp/$archive" \
    "https://github.com/neovim/neovim/releases/download/v$VERSION/$archive"
  tar -xzf "$tmp/$archive" -C "$tmp"
  # Check compatibility (e.g. glibc) before replacing an existing installation.
  "$tmp/nvim-linux-$arch/bin/nvim" --version >/dev/null
  run() { if can_root; then as_root "$@"; else "$@"; fi; }
  run mkdir -p "$prefix" "$bindir"
  if [[ -e "$dest" || -L "$dest" ]]; then
    local backup; backup="${dest}.backup.$(date +%s).$$"
    run mv -- "$dest" "$backup"
    echo "Previous installation saved to $backup"
  fi
  run mv -- "$tmp/nvim-linux-$arch" "$dest"
  can_root && as_root chown -R 0:0 "$dest"
  run ln -sfn -- "$dest/bin/nvim" "$link"
  if ! can_root && [[ ":$PATH:" != *":$bindir:"* ]]; then
    echo "Add $bindir to PATH, e.g.: echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
  fi
  "$link" --version | head -n1
}

install_packages
if version_ok; then
  echo "Neovim $(nvim --version | head -n1) is already installed."
elif [[ $OS == Linux ]]; then
  install_neovim_linux
else
  echo "Install Neovim $VERSION or newer, then rerun." >&2
  exit 1
fi

missing=()
for tool in git curl tar make cc rg jq unzip npm python3; do
  command -v "$tool" >/dev/null || missing+=("$tool")
done
if ((${#missing[@]})); then
  echo "Still missing: ${missing[*]}. Some plugins or Mason tools will not install until you add them." >&2
fi

if command -v jq >/dev/null; then bash "$ROOT/alias/setup_alias_loader.sh"; fi

# Neovim reads ~/.config/nvim; point it at this checkout if cloned elsewhere.
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [[ "$(cd -- "$CONFIG" 2>/dev/null && pwd -P)" != "$ROOT" ]]; then
  if [[ -e "$CONFIG" || -L "$CONFIG" ]]; then
    echo "Note: $CONFIG already exists and is not this checkout."
    echo "Move it aside and rerun, or start this config with: nvim -u $ROOT/init.lua"
  else
    mkdir -p "$(dirname -- "$CONFIG")"
    ln -s -- "$ROOT" "$CONFIG"
    echo "Linked $CONFIG -> $ROOT"
  fi
fi

echo
echo 'Done. Run nvim: plugins, parsers, and language servers install automatically on first launch.'
echo 'Open a new terminal (or run: source ~/.bashrc) to use aliases such as e.'
