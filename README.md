# Neovim configuration

I got bored, configured Neovim until I forgot what I was supposed to be doing, and made it public. Enjoy my questionable keybindings. HAHAHA

[Installation](#installation) · [Keybindings](#keybindings)

## Installation

Install Neovim **0.11.4+**, Git, a C compiler, make, curl, tar, and ripgrep yourself.
Language servers and formatters may also need Node.js/npm, Python, or their
language's toolchain. Use a Nerd Font for icons and a desktop clipboard provider
such as `wl-clipboard` or `xclip` on Linux.

Back up your existing configuration, then clone into Neovim's config directory:

```bash
git clone https://github.com/facelessuum/nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim
```

Lazy installs the plugins on first launch. There is no setup script, system
package installer, or shell configuration modification. For an existing install,
run `:Lazy sync` and restart Neovim. Treesitter stays on its legacy `master`
branch to match this configuration.

Install the language servers and formatters you use with `:Mason`. For example:

```vim
:MasonInstall lua-language-server pyright typescript-language-server json-lsp prettier stylua ruff
:TSInstall lua vim vimdoc query javascript typescript python bash json html css
```

Parsers and Mason tools are installed manually per machine. Run `:TSUpdate` to
update parsers and `:ConformInfo` to inspect formatter availability. Pyright
selects the nearest project `.venv` or `venv` automatically, including shared
monorepo environments, then falls back to `VIRTUAL_ENV`, `CONDA_PREFIX`, or
Python on PATH. After `uv sync`, restart Neovim if the environment was created
while the server was running. Use `:LspPyrightSetPythonPath /path/to/python` for
a manual override. Error Lens-style messages display LSP diagnostics; they do
not install or resolve dependencies themselves. Go/Rust and other optional
languages need their corresponding servers, formatters, and toolchains.

The optional Bash aliases in `alias/` are separate from Neovim and are not loaded
by this configuration.

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
| Ctrl+G | V | Run selected lines (SnipRun; detects language from filetype) |
| Shift+Tab | N, I, V | Unindent |
| Alt+F | N, I, V | Format file or selection |
| Alt+Q / Alt+E | N, I | Duplicate line below / above |
| Alt+J / Alt+K | N, I | Move line up / down |
| Shift+Up / Shift+Down | V | Move selected lines up / down |
| Ctrl+C / `c` | V | Copy selection |
| `d` | V | Delete selection |

Ctrl+W replaces Vim’s window prefix: use `:split` or `:vsplit` to create splits.
Copy/paste uses the system clipboard.

To test code, select complete lines with `V`, then press **Ctrl+G**. SnipRun
chooses an interpreter/compiler from the buffer's filetype and shows output in
Neovim. The language must be supported and its runtime/compiler installed;
selected code may need its own imports and variable definitions. This executes
code, not just a preview, so only run snippets you trust. Use `:SnipClose` to
clear the output.

For Python, SnipRun defaults to `python3` on Neovim's PATH. With **uv**, launch
Neovim from the project directory using `uv run nvim` so snippets can use the
project's installed dependencies. Restart any existing Neovim session this way;
you do not need to reinstall packages globally. For other virtual environments,
activate the environment before launching Neovim.

SnipRun's installer downloads a prebuilt binary on Linux (requires `curl`).
On macOS it builds from source, requiring the Rust toolchain (`cargo`). If the
binary does not run on your Linux architecture, build it from source by running
`sh install.sh 1` in SnipRun's plugin directory (shown in `:Lazy`).

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

File search includes dotfiles and uses Telescope's standard file-finding behavior,
including `.gitignore` rules when using ripgrep.

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
| Ctrl+S | Open selected file in a right vertical split; stay in tree |
| `i` | Return to editor in Insert mode |
| `o` | Open containing folder in system file manager |
| `r` / `d` | Rename / delete |
| `x` / `c` / `p` | Cut / copy / paste |
| `R` / `q` / `g?` | Refresh / close / full shortcut help |

The tree shows dotfiles and Git-ignored files, but hides dot directories and
`__pycache__`. Terminal/desktop shortcuts may intercept some Alt/Ctrl bindings.
