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
- Run setup as your normal user. It uses sudo if available; without sudo it
  installs Neovim **0.11.4** into `~/.local`. Supports Linux x86_64/ARM64
  (apt, dnf, pacman, zypper, apk) and macOS (Homebrew).
- Setup installs the prerequisites: Git, curl, tar, unzip, make, a C compiler,
  ripgrep, jq, Node.js/npm, and Python with venv. Use a **current Node LTS**;
  older distro Node packages may not run the latest Mason language servers.
  Linux desktop clipboard helpers (`wl-clipboard`/`xclip`) are also installed.
- It skips Neovim if you already have 0.11.4+, and links the checkout to
  `${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}` if cloned elsewhere.
  Existing configurations are never overwritten. Without sudo, add
  `export PATH="$HOME/.local/bin:$PATH"` to your shell rc file after installation.
- On macOS, install Homebrew and Apple Command Line Tools (`xcode-select --install`)
  first. On Alpine/musl, setup uses the distro Neovim package; the upstream Linux
  tarball is glibc-only. The distro package must still meet the minimum version.
- On Arch, prerequisite installation uses `pacman -Syu` (a full system upgrade)
  to avoid an unsupported partial upgrade. Review that before running setup.
- Neovim **0.11.x is the tested version**. 0.12+ is untested with the legacy
  Treesitter `master` branch; use 0.11.x if you encounter parser incompatibilities.
- On first interactive launch, plugins, Treesitter parsers, and language
  servers/formatters (via Mason) install automatically. Internet access is needed
  for installation, but installed plugins work offline. Missing runtimes are
  reported instead of failing; servers that are not installed are skipped.
  Parser/Mason auto-install does not run during headless checks. Press `q` to close Lazy.
- No compiler/make? Treesitter skips parser installation and Telescope uses its
  Lua sorter. Completion also falls back to Lua if a native matcher is unavailable.
- Shared aliases live in `alias/aliases.json`. Put machine-specific ones (project
  paths, SSH hosts) in `alias/aliases.local.json`, which Git ignores; see
  `alias/aliases.local.example.json`. Aliases are **Bash-only**; run
  `source ~/.bashrc` to load them. Desktop-opening aliases use Linux/macOS/WSL
  openers automatically. Use `bash setup.sh --no-aliases` if you use another shell.
- Use a Nerd Font for icons. Clipboard uses `wl-clipboard`/`xclip`/`xsel` on a
  desktop (macOS uses `pbcopy`/`pbpaste`); over SSH or without a usable desktop
  clipboard it copies through the terminal (OSC 52). OSC 52 requires terminal
  support, and paste returns the last copy made inside Neovim—not your desktop clipboard.

### Moving to another computer

Clone this repository and run setup on **each** computer. Keep `lazy-lock.json`
with the checkout so fresh plugin installs use the same revisions. Do **not**
copy `~/.local/share/nvim` between operating systems or CPU architectures: native
sorters, parsers, completion binaries, and Mason tools must be installed locally.
Project virtual environments are detected automatically; do not commit their paths.

Check prerequisites without installing or changing anything:

```bash
bash setup.sh --check
```

Inside Neovim, run `:checkhealth config` for this config's dependency checks,
`:Mason` for optional tools (gopls, rust-analyzer, clangd, …), and `:ConformInfo`
for formatter status. Install Go/Rust toolchains for `gofmt`/`rustfmt`, and the
appropriate runtimes for optional Java/PHP/Ruby tools. After `git pull`, run
`:Lazy restore` to match `lazy-lock.json`; `:Lazy update` deliberately changes versions.
Mason packages are installed per machine and are not pinned by Lazy's lockfile.

`setup.sh` targets Linux and macOS. On native Windows, install Neovim 0.11.4+, Git,
ripgrep, a current Node.js/npm, and Python with venv yourself; place the checkout
in Neovim's `stdpath('config')` directory (normally `%LOCALAPPDATA%\nvim`).
The shell installer and Bash aliases are not native Windows tools.

If a Treesitter install fails (for example `mv: cannot stat tree-sitter-lua-tmp/...`),
run `:Lazy restore`, then `:TSUpdate`.

### Offline regression checks

```bash
nvim --headless -u NONE -l tests/portability.lua
bash tests/setup.sh
bash -n setup.sh alias/load.sh alias/setup_alias_loader.sh
```

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

File search includes dotfiles and respects `.gitignore`. With ripgrep and a POSIX
shell plus `sort`, it also makes exceptions for ignored `.env`, `.env.*`, and `.envrc` files.
Without a POSIX shell it runs ripgrep directly; without ripgrep it falls back to
Telescope's fd/find search.

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
