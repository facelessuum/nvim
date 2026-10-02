# Sourced from ~/.bashrc. Loads aliases.json, then this machine's
# aliases.local.json (not committed), so local entries override shared ones.
NVIM_CONFIG_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
export NVIM_CONFIG_DIR

# Desktop opener differs between Linux, macOS, and WSL.
nvim_config_open() {
    if command -v xdg-open >/dev/null; then
        xdg-open "$@"
    elif command -v open >/dev/null; then
        open "$@"
    elif command -v explorer.exe >/dev/null; then
        explorer.exe "$@"
    else
        printf 'No desktop opener available on this machine.\n' >&2
        return 1
    fi
}

load_json_aliases() {
    command -v jq >/dev/null || return 0
    local alias_file
    for alias_file in "$NVIM_CONFIG_DIR/alias/aliases.json" "$NVIM_CONFIG_DIR/alias/aliases.local.json"; do
        [ -f "$alias_file" ] || continue
        eval "$(jq -r 'to_entries[] | "alias \(.key)=\(.value | @sh)"' "$alias_file" 2>/dev/null)"
    done
}
load_json_aliases
