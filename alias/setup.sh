#!/usr/bin/env bash
# Run to install and open Bash with aliases loaded; source to use this shell.
NVIM_CONFIG_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

alias f='xdg-open .'
alias e='nvim'
alias c='clear'
alias dev='npm run dev'
alias start='npm run start'
alias build='npm run build'
alias pdev='pnpm run dev'
alias pstart='pnpm run start'
alias pbuild='pnpm run build'
alias ie-time='xdg-open https://2kimai.socialtamer.com/en_US/quick_entry/ && exit'
alias gpt='xdg-open https://chat.openai.com/ && exit'
alias deepseek='xdg-open https://chat.deepseek.com/ && exit'
alias ie-res='pnpm clear && pnpm i && pnpm build && pnpm dev'
alias pewpew='source .venv/bin/activate'
alias pew='deactivate'

# Resume the latest session with this exact name in the current project.
# Called in the Pi tab's shell; only create a session when none exists.
pi-resume-named() {
    local session
    session=$(python3 - "$1" <<'PY'
import json
import os
from pathlib import Path
import re
import sys

cwd = Path.cwd()
agent = Path(os.environ.get("PI_CODING_AGENT_DIR") or "~/.pi/agent").expanduser()
custom = os.environ.get("PI_CODING_AGENT_SESSION_DIR")
if not custom:
    try:
        custom = json.loads((agent / "settings.json").read_text()).get("sessionDir")
    except FileNotFoundError:
        pass
if custom:
    directory = Path(custom).expanduser().resolve()
else:
    encoded = "--" + re.sub(r"[/\\:]", "-", str(cwd)[1:]) + "--"
    directory = agent / "sessions" / encoded

candidates = []
if directory.exists():
    for path in directory.glob("*.jsonl"):
        try:
            candidates.append((path.stat().st_mtime_ns, path))
        except FileNotFoundError:
            pass
for _, path in sorted(candidates, reverse=True):
    try:
        with path.open() as stream:
            header = json.loads(next(stream, "{}"))
            if not isinstance(header, dict) or header.get("type") != "session":
                continue
            if not header.get("cwd") or Path(header["cwd"]).resolve() != cwd:
                continue
            name = None
            for line in stream:
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if isinstance(entry, dict) and entry.get("type") == "session_info":
                    name = entry.get("name")
            if name == sys.argv[1]:
                print(path.resolve())
                break
    except (FileNotFoundError, json.JSONDecodeError):
        continue
PY
    ) || return
    if [[ -n "$session" ]]; then
        exec pi --session "$session"
    else
        exec pi --name "$1"
    fi
}

# Launch three Pi tabs separately, then open Neovim in the current terminal.
alias ai-ie='cd /home/umm/projects/ie-ai-2 && gnome-terminal \
    --window --working-directory=/home/umm/projects/ie-ai-2 --title=review-commit \
    -- bash -ic "
        gnome-terminal --tab --working-directory=/home/umm/projects/ie-ai-2 --title=ideas \\
            -- bash -ic \"pi-resume-named ideas\"
        gnome-terminal --tab --working-directory=/home/umm/projects/ie-ai-2 --title=worker \\
            -- bash -ic \"pi-resume-named worker\"
        pi-resume-named review-commit
    " && conda activate ie-ai-2 && nvim'

alias ai-prac='cd /home/umm/projects/ai-practice-py && gnome-terminal \
    --window --working-directory=/home/umm/projects/ai-practice-py --title=review-commit \
    -- bash -ic "
        gnome-terminal --tab --working-directory=/home/umm/projects/ai-practice-py --title=ideas \\
            -- bash -ic \"pi-resume-named ideas\"
        gnome-terminal --tab --working-directory=/home/umm/projects/ai-practice-py --title=worker \\
            -- bash -ic \"pi-resume-named worker\"
        pi-resume-named review-commit
    " && nvim'

alias ai-floor='cd /home/umm/projects/aiFloor && gnome-terminal \
    --window --working-directory=/home/umm/projects/aiFloor --title=review-commit \
    -- bash -ic "
        gnome-terminal --tab --working-directory=/home/umm/projects/aiFloor --title=ideas \\
            -- bash -ic \"pi-resume-named ideas\"
        gnome-terminal --tab --working-directory=/home/umm/projects/aiFloor --title=worker \\
            -- bash -ic \"pi-resume-named worker\"
        pi-resume-named review-commit
    " && conda activate aifloor && nvim'

# Register this same file for future Bash terminals (and replace the old loader).
# Keep setup variables and failure exits inside a subshell.
if ! (
    alias_bashrc="$HOME/.bashrc"
    alias_line="source $(printf '%q' "$NVIM_CONFIG_DIR/alias/setup.sh") # nvim-config aliases"
    if ! grep -qFx "$alias_line" "$alias_bashrc" 2>/dev/null; then
        touch "$alias_bashrc" || exit 1
        alias_tmp=$(mktemp) || exit 1
        trap 'rm -f "$alias_tmp"' EXIT
        grep -vF '# nvim-config aliases' "$alias_bashrc" > "$alias_tmp" || [[ $? -eq 1 ]] || exit 1
        printf '\n%s\n' "$alias_line" >> "$alias_tmp" && cat "$alias_tmp" > "$alias_bashrc" || exit 1
    fi
); then
    if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
        exit 1
    else
        return 1
    fi
fi

# An executed script cannot update its parent shell, so start a loaded Bash.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ -t 0 && -t 1 ]]; then
        exec bash --rcfile "$HOME/.bashrc" -i
    fi
    printf 'Aliases installed. They will load automatically in new Bash terminals.\n'
fi
