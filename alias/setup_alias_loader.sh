#!/usr/bin/env bash
# Register this checkout's aliases in ~/.bashrc, wherever the repo was cloned.
set -euo pipefail

command -v jq >/dev/null || { echo 'Missing jq; install it first.' >&2; exit 1; }
ALIAS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# Fail before editing shell configuration if an alias file is invalid.
for json in "$ALIAS_DIR/aliases.json" "$ALIAS_DIR/aliases.local.json"; do
  [[ -f "$json" ]] || continue
  jq -e 'type == "object" and all(.[]; type == "string")' "$json" >/dev/null \
    || { echo "Invalid alias file: $json" >&2; exit 1; }
done

LINE="[ -f $(printf '%q' "$ALIAS_DIR/load.sh") ] && . $(printf '%q' "$ALIAS_DIR/load.sh") # nvim-config aliases"
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
if grep -qF '# nvim-config aliases' "$BASHRC"; then
  # Update the path in case the repo moved.
  tmp=$(mktemp)
  grep -vF '# nvim-config aliases' "$BASHRC" > "$tmp" || true
  printf '%s\n' "$LINE" >> "$tmp"
  cat "$tmp" > "$BASHRC"
  rm -f "$tmp"
  echo 'Updated alias loader in ~/.bashrc.'
else
  printf '\n%s\n' "$LINE" >> "$BASHRC"
  echo 'Added alias loader to ~/.bashrc.'
fi
if grep -q '^load_json_aliases() {' "$BASHRC"; then
  echo 'Note: ~/.bashrc also has an older load_json_aliases block; you can delete it.'
fi
echo 'Per-machine aliases go in alias/aliases.local.json (see aliases.local.example.json).'
# Do not source .bashrc here: a child process cannot change its parent shell.
echo 'Open a new Bash terminal or run: source ~/.bashrc'
