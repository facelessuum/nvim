#!/usr/bin/env bash
# Install prerequisites on Linux/macOS without password prompts. Run as your normal user.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
VERSION="${NVIM_VERSION:-0.11.4}"
OS="$(uname -s)"
CHECK_ONLY=false
INSTALL_ALIASES=true
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=true ;;
    --no-aliases) INSTALL_ALIASES=false ;;
    *) echo "Usage: bash setup.sh [--check] [--no-aliases]" >&2; exit 2 ;;
  esac
done
[[ $VERSION =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || { echo 'NVIM_VERSION must be a version such as 0.11.4.' >&2; exit 2; }
REQUIRED_MAJOR=${BASH_REMATCH[1]}
REQUIRED_MINOR=${BASH_REMATCH[2]}
REQUIRED_PATCH=${BASH_REMATCH[3]}
if (( REQUIRED_MAJOR == 0 && (REQUIRED_MINOR < 11 || (REQUIRED_MINOR == 11 && REQUIRED_PATCH < 4)) )); then
  echo 'This config requires Neovim 0.11.4 or newer.' >&2
  exit 2
fi

version_ok() {
  command -v nvim >/dev/null || return 1
  local output major minor patch
  output=$(nvim --version) || return 1
  [[ $output =~ ^NVIM\ v([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
  major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}; patch=${BASH_REMATCH[3]}
  # Numeric comparison works on macOS too (BSD sort has no -V flag).
  (( major > REQUIRED_MAJOR || (major == REQUIRED_MAJOR && minor > REQUIRED_MINOR) ||
    (major == REQUIRED_MAJOR && minor == REQUIRED_MINOR && patch >= REQUIRED_PATCH) ))
}

check_tools() {
  local tool compiler missing=()
  for tool in git curl tar make rg jq unzip node npm python3; do
    command -v "$tool" >/dev/null || missing+=("$tool")
  done
  compiler=false
  for tool in "${CC:-cc}" cc gcc clang zig; do
    if command -v "$tool" >/dev/null; then compiler=true; break; fi
  done
  $compiler || missing+=("C compiler")
  if command -v python3 >/dev/null && ! python3 -c 'import venv, ensurepip' >/dev/null 2>&1; then
    missing+=("Python venv/ensurepip (python3-venv on Debian/Ubuntu)")
  fi
  if ((${#missing[@]})); then
    printf 'Missing prerequisite: %s\n' "${missing[@]}" >&2
    return 1
  fi
  echo 'Prerequisites are available.'
}

# This mode never installs anything, invokes sudo, or edits shell configuration.
if $CHECK_ONLY; then
  status=0
  version_ok || { echo "Neovim $VERSION+ is missing from PATH." >&2; status=1; }
  check_tools || status=1
  exit "$status"
fi

case "$OS" in
  Linux|Darwin) ;;
  *) echo 'setup.sh supports Linux and macOS. On Windows, install Neovim and prerequisites manually (see README).' >&2; exit 1 ;;
esac

SUDO=()
if [[ $OS == Linux && $EUID -ne 0 ]]; then
  # Never prompt for credentials, including if authorization expires mid-setup.
  if command -v sudo >/dev/null && sudo -n true 2>/dev/null; then SUDO=(sudo -n); else SUDO=(none); fi
fi
can_root() { [[ ${SUDO[0]:-} != none ]]; }
as_root() { if [[ ${#SUDO[@]} -eq 0 ]]; then "$@"; else "${SUDO[@]}" "$@"; fi; }

install_packages() {
  if [[ $OS == Darwin ]]; then
    command -v brew >/dev/null || { echo 'Install Homebrew first: https://brew.sh' >&2; return 1; }
    # Apple Command Line Tools provide cc/make; do not install them in the background.
    xcode-select -p >/dev/null 2>&1 || { echo 'Run xcode-select --install, then rerun setup.' >&2; return 1; }
    brew install git curl ripgrep jq unzip node python neovim
    if ! version_ok; then brew upgrade neovim; fi
  elif ! can_root; then
    echo 'No passwordless sudo: skipping system packages; missing dependencies will be listed below.' >&2
  elif command -v apt-get >/dev/null; then
    as_root apt-get update
    as_root apt-get install -y curl ca-certificates tar gzip unzip git build-essential ripgrep jq \
      nodejs npm python3 python3-venv python3-pip
    # Clipboard helpers are optional on minimal/headless systems.
    as_root apt-get install -y wl-clipboard xclip || echo 'Clipboard packages unavailable; using OSC 52.' >&2
  elif command -v dnf >/dev/null; then
    as_root dnf install -y curl tar gzip unzip git gcc make ripgrep jq nodejs npm python3 python3-pip
    as_root dnf install -y wl-clipboard xclip || echo 'Clipboard packages unavailable; using OSC 52.' >&2
  elif command -v pacman >/dev/null; then
    # Avoid a partial Arch upgrade (pacman -Sy followed by package installs).
    as_root pacman -Syu --needed --noconfirm curl tar gzip unzip git base-devel ripgrep jq nodejs npm python python-pip wl-clipboard xclip
  elif command -v zypper >/dev/null; then
    as_root zypper install -y curl tar gzip unzip git gcc make ripgrep jq nodejs npm python3 python3-pip
    as_root zypper install -y wl-clipboard xclip || echo 'Clipboard packages unavailable; using OSC 52.' >&2
  elif command -v apk >/dev/null; then
    # Alpine uses musl; the upstream Linux Neovim tarball requires glibc.
    as_root apk add ca-certificates curl tar gzip unzip git build-base ripgrep jq nodejs npm python3 py3-pip neovim
    as_root apk add wl-clipboard xclip || echo 'Clipboard packages unavailable; using OSC 52.' >&2
  else
    echo 'Unknown package manager: install prerequisites manually.' >&2
  fi
}

install_neovim_linux() {
  if [[ -f /etc/alpine-release ]] || compgen -G '/lib/ld-musl-*.so*' >/dev/null; then
    echo "This is a musl system. Install Neovim $VERSION+ using your distribution, not the glibc tarball." >&2
    return 1
  fi
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
  local archive="nvim-linux-$arch.tar.gz"
  curl --fail --location --retry 3 --output "$TMP/$archive" \
    "https://github.com/neovim/neovim/releases/download/v$VERSION/$archive"
  tar -xzf "$TMP/$archive" -C "$TMP"
  # Check compatibility before touching an existing installation.
  "$TMP/nvim-linux-$arch/bin/nvim" --version >/dev/null
  run() { if can_root; then as_root "$@"; else "$@"; fi; }
  run mkdir -p "$prefix" "$bindir"
  if [[ -e "$dest" || -L "$dest" ]]; then
    local backup; backup="${dest}.backup.$(date +%s).$$"
    run mv -- "$dest" "$backup"
    echo "Previous installation saved to $backup"
  fi
  run mv -- "$TMP/nvim-linux-$arch" "$dest"
  if can_root; then as_root chown -R 0:0 "$dest"; fi
  run ln -sfn -- "$dest/bin/nvim" "$link"
  export PATH="$bindir:$PATH"
  hash -r
  echo "Installed $link. Ensure $bindir comes first in your shell's PATH."
  if ! can_root; then
    echo 'Add this to your shell rc file: export PATH="$HOME/.local/bin:$PATH"'
  fi
}

if check_tools >/dev/null 2>&1 && { [[ $OS != Darwin ]] || version_ok; }; then
  echo 'Prerequisites are already available; skipping system packages.'
else
  install_packages
fi
if version_ok; then
  echo 'A compatible Neovim is already installed.'
elif [[ $OS == Linux ]]; then
  install_neovim_linux
fi
version_ok || { echo "Install Neovim $VERSION+ and put it on PATH, then rerun." >&2; exit 1; }
check_tools || echo 'Some plugin features will be unavailable until you install the missing prerequisites.' >&2

if $INSTALL_ALIASES && command -v jq >/dev/null; then
  bash "$ROOT/alias/setup_alias_loader.sh"
fi

# Respect both XDG_CONFIG_HOME and alternate Neovim profiles.
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}"
if [[ "$(cd -- "$CONFIG" 2>/dev/null && pwd -P)" != "$ROOT" ]]; then
  if [[ -e "$CONFIG" || -L "$CONFIG" ]]; then
    echo "Note: $CONFIG already exists and is not this checkout. It was not changed."
    printf 'Move it aside and rerun, or start this config with: nvim -u %q\n' "$ROOT/init.lua"
  else
    mkdir -p "$(dirname -- "$CONFIG")"
    ln -s -- "$ROOT" "$CONFIG"
    echo "Linked $CONFIG -> $ROOT"
  fi
fi

echo
echo 'Done. Run nvim: plugins, parsers, and Mason tools install on first interactive launch.'
echo 'Use :checkhealth config for machine-specific dependency checks.'
if $INSTALL_ALIASES; then echo 'Aliases are Bash-only: open a Bash terminal or run source ~/.bashrc.'; fi
