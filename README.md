# Neovim configuration

I got bored, configured Neovim until I forgot what I was supposed to be doing, and made it public. Enjoy my questionable keybindings. HAHAHA

[Installation](#installation) · [Keybindings](#keybindings)

## Installation

Back up your existing Neovim configuration first, then run:

```bash
git clone https://github.com/facelessuum/nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
cd "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
bash setup.sh
nvim
```

- Install Git first (`sudo apt install git` on Ubuntu/Debian).
- Run setup as your normal user; it requests sudo when needed. Supports Linux
  x86_64/ARM64, installs Neovim **0.11.4**, and registers Bash aliases.
- Ubuntu/Debian prerequisites are installed automatically. Elsewhere, install
  curl, tar, Git, make, a C compiler, ripgrep, and jq yourself.
- Already have Neovim **0.11.4+** and the prerequisites? Skip `setup.sh` (also on macOS).
- Wait for plugins and parsers to install on first launch. Press `q` to close Lazy.
- Review personal shortcuts in `alias/aliases.json`; run `source ~/.bashrc` in Bash
  to enable aliases such as `e` for `nvim`.
- Use a Nerd Font for icons and a clipboard provider such as `xclip` (X11) or
  `wl-clipboard` (Wayland).

Install the language servers and formatters you need **inside Neovim**, for example:

```vim
:MasonInstall typescript-language-server pyright ty json-lsp
:MasonInstall prettier stylua ruff shfmt
```

Use `:Mason` for other tools, `:checkhealth` for problems, and `:ConformInfo` for
formatter status. Tools may need separate runtimes and project dependencies.
Restart after installing servers. After `git pull`, use `:Lazy restore` to match
`lazy-lock.json`.

## Keybindings

**N** = Normal, **I** = Insert, **V** = Visual, **T** = terminal input.
Leader is **Space**; `jk` is a sequence. Plugin-local bindings take priority.

**Files autosave after 500 ms of idle typing.** Formatting is manual.

### Editor

| Shortcut | Mode | Action |
| --- | --- | --- |
| `;` / `jk` | N / I | Command line / leave Insert mode |
| Alt+W / A / S / D | N, I, V | Move up / left / down / right |
| Alt+Shift+W / A / S / D | N, I, V | Focus split above / left / below / right |
| Ctrl+W | N, I, V, T | Close window; confirm unsaved changes; final window exits |
| `n` / Ctrl+K | N / N, I | Next tab |
| Ctrl+Q | N, I | **Force-close tab**, potentially discarding edits |
| Ctrl+E | N, I | Find files |
| Space, then `b` | N | Search open buffers |
| Alt+L | N, I, V | Search current-file text |
| Ctrl+F | N, I | Toggle tree and reveal current file |
| Alt+Enter | N, I | Go to definition; Esc then Ctrl+O to return |
| Ctrl+C / Ctrl+X / Ctrl+V | N, I | Copy line / cut line / paste; enter Insert mode |
| Ctrl+Z / Ctrl+Y | N, I | Undo / redo |
| Ctrl+A | N, I | Select all lines |
| Ctrl+R | N, I, V | Delete word under cursor |
| Shift+Tab | N, I, V | Unindent |
| Alt+F | N, I, V | Format file or selection |
| Alt+Q / Alt+E | N, I | Duplicate line below / above |
| Alt+J / Alt+K | N, I | Move line up / down |
| Shift+Up / Shift+Down | V | Move selected lines up / down |
| Ctrl+C / `c` | V | Copy selection |
| `d` | V | Delete selection |

Ctrl+W replaces Vim’s window prefix: use `:split` or `:vsplit` to create splits.
Copy/paste uses the system clipboard.

### Telescope

| Shortcut | Action |
| --- | --- |
| Enter | Reuse file’s tab or open a new one; Alt+L instead jumps within current file |
| Alt+W / A / S / D | Open in split above / left / below / right |
| Alt+Enter | Open in vertical split |
| Up / Down | Previous / next result |
| Ctrl+A | Select prompt text in Insert mode |
| Ctrl+W | Close picker |
| Esc | Leave Insert mode; press again to close |
| Ctrl+/ (Insert) / `?` (Normal) | Show picker bindings |

File search includes dotfiles, respects `.gitignore`, and makes exceptions for
`.env`, `.env.*`, and `.envrc`. Requires ripgrep.

### Completion

| Shortcut | Action in Insert mode |
| --- | --- |
| Tab | Accept completion, otherwise next snippet placeholder, otherwise Tab |
| Enter | Accept selected completion, otherwise newline |
| Up / Down, Ctrl+P / Ctrl+N | Previous / next suggestion |
| Ctrl+Space | Show completion / toggle documentation |
| Ctrl+E | Cancel completion |
| Ctrl+B / Ctrl+F | Scroll documentation |
| Ctrl+K | Toggle signature help |
| Shift+Tab / Ctrl+Y | Unindent / redo (not snippet-back / accept) |

### Multiple cursors

| Shortcut | Action |
| --- | --- |
| Ctrl+D | Select word or Visual selection; repeat for next match |
| Ctrl+L | Select current line as editable region |
| Ctrl+Shift+L | Select all matches, if supported by terminal |
| Alt+Click | Add cursor |
| Type / Backspace / Delete | Replace / delete selections |
| Ctrl+Z | Undo |
| Esc | End multicursor editing |

Type directly to replace selections—no `c` or `i` needed.

### Terminal

| Shortcut | Action |
| --- | --- |
| Ctrl+J | Toggle panel (N, I, V, T); hiding keeps shells alive |
| Alt+N / Alt+X / Alt+T | New session / delete session / focus list (N, I, V, T) |
| Alt+D | Next session while in terminal buffer or list |
| `n` / Enter / `d` / `q` | In list: new / switch / delete / hide |
| Ctrl+\, then Ctrl+N | Leave shell input mode; `i` resumes |

Deleting a session stops its job. Ctrl+C in shell input mode interrupts commands.

### File tree

| Shortcut | Action in tree Normal mode |
| --- | --- |
| `n` | Create file with extension, otherwise folder; trailing `/` forces folder |
| `a` | Standard create prompt (use for extensionless files) |
| Enter / `s` / double-click | Open file or toggle folder; stay in tree |
| `i` | Return to editor in Insert mode |
| `o` | Open containing folder in system file manager |
| `r` / `d` | Rename / delete |
| `x` / `c` / `p` | Cut / copy / paste |
| `R` / `q` / `g?` | Refresh / close / full shortcut help |

The tree shows dotfiles and Git-ignored files, but hides dot directories and
`__pycache__`. Terminal/desktop shortcuts may intercept some Alt/Ctrl bindings.
