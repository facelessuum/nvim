#!/usr/bin/env bash
# Real Git checkout regression tests using a local fixture; no network or sudo.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
REAL_GIT=$(command -v git)
NVIM_BIN=$(command -v nvim)
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
# Do not let the caller's dotfile Git setup affect fixture creation either.
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
export GIT_CONFIG_GLOBAL="$TMP/gitconfig" GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME='Setup Test' GIT_AUTHOR_EMAIL='setup-test@example.invalid'
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
mkdir -p "$TMP/fixture/lua/nvim-treesitter" "$TMP/config/scripts" "$TMP/bin" "$TMP/wrong-tree"
cp "$ROOT/scripts/setup_treesitter.lua" "$TMP/config/scripts/"
"$REAL_GIT" -C "$TMP/fixture" init -q
"$REAL_GIT" -C "$TMP/fixture" symbolic-ref HEAD refs/heads/master
printf 'return {}\n' > "$TMP/fixture/lua/nvim-treesitter/configs.lua"
"$REAL_GIT" -C "$TMP/fixture" add .
"$REAL_GIT" -C "$TMP/fixture" commit -qm 'legacy fixture'
legacy=$("$REAL_GIT" -C "$TMP/fixture" rev-parse HEAD)
# Model a stale lock entry: branch says master, but the commit has the new API.
rm "$TMP/fixture/lua/nvim-treesitter/configs.lua"
printf 'return { setup = function() end }\n' > "$TMP/fixture/lua/nvim-treesitter/init.lua"
"$REAL_GIT" -C "$TMP/fixture" add -A
"$REAL_GIT" -C "$TMP/fixture" commit -qm 'modern fixture'
modern=$("$REAL_GIT" -C "$TMP/fixture" rev-parse HEAD)

# Substitute only the public repository URL. Everything else uses real Git.
cat > "$TMP/bin/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
for name in GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES; do
  [[ -z ${!name:-} ]] || { echo "$name leaked into setup's Git command" >&2; exit 99; }
done
args=("$@")
for i in "${!args[@]}"; do
  if [[ ${args[$i]} == https://github.com/nvim-treesitter/nvim-treesitter.git ]]; then
    args[$i]=$TEST_FIXTURE
  fi
done
exec "$REAL_GIT" "${args[@]}"
SH
chmod +x "$TMP/bin/git"
export REAL_GIT TEST_FIXTURE="$TMP/fixture"
export PATH="$TMP/bin:$PATH" XDG_DATA_HOME="$TMP/data" NVIM_APPNAME=repair-test GIT_TERMINAL_PROMPT=0
plugin="$XDG_DATA_HOME/$NVIM_APPNAME/lazy/nvim-treesitter"
mkdir -p "$plugin"
printf 'preserve me\n' > "$plugin/marker"
printf '{"nvim-treesitter":{"branch":"master","commit":"%s"}}\n' "$legacy" > "$TMP/config/lazy-lock.json"
# Simulate global checkout settings as well as inherited bare-repo variables.
printf '[core]\n\tsparseCheckout = true\n\tworktree = %s\n' "$TMP/wrong-tree" > "$GIT_CONFIG_GLOBAL"

repair() {
  GIT_DIR="$TMP/redirect.git" GIT_WORK_TREE="$TMP/wrong-tree" \
    GIT_COMMON_DIR="$TMP/redirect-common" GIT_INDEX_FILE="$TMP/redirect-index" \
    GIT_OBJECT_DIRECTORY="$TMP/redirect-objects" GIT_ALTERNATE_OBJECT_DIRECTORIES="$TMP/redirect-alternates" \
    "$NVIM_BIN" --headless -u NONE -l "$TMP/config/scripts/setup_treesitter.lua" > "$TMP/output" 2>&1
}
repair || { printf 'Real checkout test failed:\n' >&2; grep . "$TMP/output" >&2; exit 1; }
[[ -f "$plugin/lua/nvim-treesitter/configs.lua" ]]
# Avoid the poisoned global worktree when inspecting the result.
[[ $("$REAL_GIT" -C "$plugin" rev-parse HEAD) == "$legacy" ]]
backups=("$XDG_DATA_HOME/$NVIM_APPNAME/treesitter-backups"/*)
[[ ${#backups[@]} -eq 1 && -f "${backups[0]}/marker" ]]
[[ ! -e "$TMP/wrong-tree/lua/nvim-treesitter/configs.lua" ]]
printf 'ok 1 - real checkout handles inherited Git variables and global sparse/worktree settings\n'

repair
grep -q 'already matches lazy-lock.json' "$TMP/output"
printf 'ok 2 - real matching checkout is idempotent\n'

printf '{"nvim-treesitter":{"branch":"master","commit":"%s"}}\n' "$modern" > "$TMP/config/lazy-lock.json"
status=0
repair || status=$?
[[ $status -eq 1 ]]
grep -q "lockfile revision $modern could not be verified as a legacy revision" "$TMP/output"
grep -q 'git restore --source=HEAD -- lazy-lock.json' "$TMP/output"
[[ $("$REAL_GIT" -C "$plugin" rev-parse HEAD) == "$legacy" ]]
[[ -f "$plugin/lua/nvim-treesitter/configs.lua" ]]
printf 'ok 3 - real incompatible lockfile revision is diagnosed without replacing the plugin\n'
printf 'Passed 3 real Git checkout checks.\n'
