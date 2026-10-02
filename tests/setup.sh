#!/usr/bin/env bash
# Check installer version logic with a minimal, simulated macOS PATH.
# No package managers, network access, sudo, or shell rc edits are allowed.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
BASH_BIN=$(command -v bash)
RM_BIN=$(command -v rm)
TMP=$(mktemp -d)
trap '"$RM_BIN" -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/home"
ln -s "$(command -v dirname)" "$TMP/bin/dirname"
cat > "$TMP/bin/nvim" <<'SH'
#!/bin/sh
printf 'NVIM v%s\nBuild type: Release\n' "$NVIM_TEST_VERSION"
SH
cat > "$TMP/bin/uname" <<'SH'
#!/bin/sh
printf 'Darwin\n'
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
printf 'Passed %s installer checks; no side effects.\n' "$count"
