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

# Launch three Pi tabs separately, then open Neovim in the current terminal.
alias ai-ie='cd /home/umm/projects/ie-ai-2 && gnome-terminal \
    --window --working-directory=/home/umm/projects/ie-ai-2 --title=review-commit \
    -- bash -ic "
        gnome-terminal --tab --working-directory=/home/umm/projects/ie-ai-2 --title=ideas \\
            -- bash -ic \"exec pi --name ideas\"
        gnome-terminal --tab --working-directory=/home/umm/projects/ie-ai-2 --title=worker \\
            -- bash -ic \"exec pi --name worker\"
        exec pi --name review-commit
    " && nvim'

alias ai-prac='cd /home/umm/projects/ai-practice-py && gnome-terminal \
    --window --working-directory=/home/umm/projects/ai-practice-py --title=review-commit \
    -- bash -ic "
        gnome-terminal --tab --working-directory=/home/umm/projects/ai-practice-py --title=ideas \\
            -- bash -ic \"exec pi --name ideas\"
        gnome-terminal --tab --working-directory=/home/umm/projects/ai-practice-py --title=worker \\
            -- bash -ic \"exec pi --name worker\"
        exec pi --name review-commit
    " && nvim'

alias ai-floor='cd /home/umm/projects/aiFloor && gnome-terminal \
    --window --working-directory=/home/umm/projects/aiFloor --title=review-commit \
    -- bash -ic "
        gnome-terminal --tab --working-directory=/home/umm/projects/aiFloor --title=ideas \\
            -- bash -ic \"exec pi --name ideas\"
        gnome-terminal --tab --working-directory=/home/umm/projects/aiFloor --title=worker \\
            -- bash -ic \"exec pi --name worker\"
        exec pi --name review-commit
    " && nvim'

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
