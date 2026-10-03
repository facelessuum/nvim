#!/usr/bin/env bash
# Check version logic and passwordless setup using a simulated PATH.
# Only mocked package managers/sudo/nvim are invoked; no network or rc edits.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
BASH_BIN=$(command -v bash)
RM_BIN=$(command -v rm)
CHMOD_BIN=$(command -v chmod)
CAT_BIN=$(command -v cat)
TMP=$(mktemp -d)
trap '"$RM_BIN" -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/home" "$TMP/config"
ln -s "$ROOT" "$TMP/config/nvim"
for tool in dirname mkdir ln mv date rm mktemp; do
  ln -s "$(command -v "$tool")" "$TMP/bin/$tool"
done
cat > "$TMP/bin/nvim" <<'SH'
#!/bin/sh
if [ "$1" = --version ]; then
  printf 'NVIM v%s\nBuild type: Release\n' "$NVIM_TEST_VERSION"
elif [ "$1" = --headless ] && [ "$2" = -u ] && [ "$3" = NONE ] && [ "$4" = -l ] && [ "$GIT_TERMINAL_PROMPT" = 0 ]; then
  printf '%s\n' "$5" > "$TEST_REPAIR"
else
  exit 99
fi
SH
cat > "$TMP/bin/uname" <<'SH'
#!/bin/sh
if [ "${1:-}" = -m ]; then
  printf 'x86_64\n'
else
  printf '%s\n' "${NVIM_TEST_OS:-Darwin}"
fi
SH
cat > "$TMP/bin/tool" <<'SH'
#!/bin/sh
exit 0
SH
cat > "$TMP/bin/forbidden" <<'SH'
#!/bin/sh
printf 'forbidden command invoked\n' > "$TEST_FORBIDDEN"
exit 99
SH
chmod +x "$TMP/bin/nvim" "$TMP/bin/uname" "$TMP/bin/tool" "$TMP/bin/forbidden"
for tool in git curl tar make cc rg jq unzip node npm python3; do
  ln -s tool "$TMP/bin/$tool"
done
for tool in sudo brew sort apt-get; do ln -s forbidden "$TMP/bin/$tool"; done
export TEST_FORBIDDEN="$TMP/forbidden"
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config"
export NVIM_APPNAME=nvim
export PATH="$TMP/bin"
unset CC NVIM_VERSION

count=0
check_version() {
  local version=$1 expected=$2 status=0
  NVIM_TEST_VERSION=$version "$BASH_BIN" "$ROOT/setup.sh" --check > "$TMP/output" 2>&1 || status=$?
  if [[ $status -ne $expected ]]; then
    printf 'FAIL: Neovim %s gave status %s, expected %s\n' "$version" "$status" "$expected" >&2
    exit 1
  fi
  count=$((count + 1))
  printf 'ok %s - Neovim %s (expected exit %s)\n' "$count" "$version" "$expected"
}
check_version 0.11.4 0
check_version 0.11.10 0
check_version 0.11.3 1
check_version 0.10.99 1
check_version 0.12.0 0
check_version 1.0.0 0
check_version 0.11.4-dev 0
[[ ! -e "$TEST_FORBIDDEN" && ! -e "$HOME/.bashrc" ]] || { echo '--check had forbidden side effects' >&2; exit 1; }
printf 'Passed %s version checks; no side effects.\n' "$count"

# Normal setup must run the repair without loading init.lua. Mock sudo refuses
# any invocation without -n, so no password prompt can sneak into these tests.
"$RM_BIN" "$TMP/bin/sudo" "$TMP/bin/apt-get"
"$CAT_BIN" > "$TMP/bin/sudo" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_SUDO_LOG"
if [ "$1" != -n ]; then
  printf 'interactive sudo invoked\n' > "$TEST_FORBIDDEN"
  exit 99
fi
shift
[ "${TEST_SUDO_ALLOWED:-0}" = 1 ] || exit 1
exec "$@"
SH
"$CAT_BIN" > "$TMP/bin/apt-get" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_PACKAGES_LOG"
SH
"$CHMOD_BIN" +x "$TMP/bin/sudo" "$TMP/bin/apt-get"
export NVIM_TEST_VERSION=0.11.4 NVIM_TEST_OS=Linux
export TEST_REPAIR="$TMP/repair" TEST_SUDO_LOG="$TMP/sudo-log" TEST_PACKAGES_LOG="$TMP/packages-log"
# Supply true to the mocked sudo probe without expanding the host PATH.
"$CAT_BIN" > "$TMP/bin/true" <<'SH'
#!/bin/sh
exit 0
SH
"$CHMOD_BIN" +x "$TMP/bin/true"

check_setup() {
  "$RM_BIN" -f "$TEST_REPAIR" "$TEST_SUDO_LOG" "$TEST_PACKAGES_LOG"
  "$BASH_BIN" "$ROOT/setup.sh" --no-aliases > "$TMP/output" 2>&1
  [[ $(<"$TEST_REPAIR") == "$ROOT/scripts/setup_treesitter.lua" ]] || { echo 'Treesitter repair not invoked' >&2; exit 1; }
  [[ ! -e "$TEST_FORBIDDEN" && ! -e "$HOME/.bashrc" ]] || { echo 'setup had forbidden side effects' >&2; exit 1; }
  count=$((count + 1))
}
check_setup
[[ ! -e "$TEST_PACKAGES_LOG" ]] || { echo 'Unnecessary package install' >&2; exit 1; }
printf 'ok %s - available prerequisites skip package installation and run repair\n' "$count"

if [[ $EUID -ne 0 ]]; then
  "$RM_BIN" "$TMP/bin/make"
  check_setup
  [[ $(<"$TEST_SUDO_LOG") == '-n true' && ! -e "$TEST_PACKAGES_LOG" ]] || { echo 'No-sudo fallback failed' >&2; exit 1; }
  printf 'ok %s - missing prerequisites do not trigger a sudo password prompt\n' "$count"

  export TEST_SUDO_ALLOWED=1
  check_setup
  [[ -s "$TEST_PACKAGES_LOG" ]] || { echo 'Passwordless package installation skipped' >&2; exit 1; }
  while IFS= read -r invocation; do
    [[ $invocation == '-n '* ]] || { echo 'sudo command missing -n' >&2; exit 1; }
  done < "$TEST_SUDO_LOG"
  printf 'ok %s - every passwordless sudo command uses -n\n' "$count"

  # Exercise the actual user-local installation path with a fake release archive.
  export TEST_SUDO_ALLOWED=0 NVIM_TEST_VERSION=0.10.4
  "$RM_BIN" "$TMP/bin/curl" "$TMP/bin/tar"
  "$CAT_BIN" > "$TMP/bin/curl" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  if [ "$1" = --output ]; then shift; printf 'fake archive\n' > "$1"; exit 0; fi
  shift
done
exit 99
SH
  "$CAT_BIN" > "$TMP/bin/tar" <<'SH'
#!/bin/sh
[ "$1" = -xzf ] && [ "$3" = -C ] || exit 99
mkdir -p "$4/nvim-linux-x86_64/bin"
cat > "$4/nvim-linux-x86_64/bin/nvim" <<'NVIM'
#!/bin/sh
if [ "$1" = --version ]; then
  printf 'NVIM v0.11.4\n'
elif [ "$1" = --headless ] && [ "$2" = -u ] && [ "$3" = NONE ] && [ "$4" = -l ] && [ "$GIT_TERMINAL_PROMPT" = 0 ]; then
  printf '%s\n' "$5" > "$TEST_REPAIR"
else
  exit 99
fi
NVIM
chmod +x "$4/nvim-linux-x86_64/bin/nvim"
SH
  # These commands are only needed by the mocked archive extractor.
  ln -s "$CAT_BIN" "$TMP/bin/cat"
  ln -s "$CHMOD_BIN" "$TMP/bin/chmod"
  "$CHMOD_BIN" +x "$TMP/bin/curl" "$TMP/bin/tar"
  check_setup
  [[ -L "$HOME/.local/bin/nvim" && -x "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" ]] || { echo 'User-local Neovim not installed' >&2; exit 1; }
  [[ $(<"$TEST_SUDO_LOG") == '-n true' && ! -e "$TEST_PACKAGES_LOG" ]] || { echo 'User-local install used sudo' >&2; exit 1; }
  printf 'ok %s - Neovim installs under HOME and runs repair without root\n' "$count"
else
  echo 'Skipping sudo fallback cases when tests run as root.'
fi
printf 'Passed %s installer checks.\n' "$count"
