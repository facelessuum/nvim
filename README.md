# Neovim configuration

I got bored, configured Neovim until I forgot what I was supposed to be doing, and made it public. Enjoy my questionable keybindings. HAHAHA

[Installation](#installation) · [Keybindings](#keybindings)

## Installation

### 1. Install Git (Ubuntu/Debian)

Run these commands **in your terminal**, as your normal user:

```bash
sudo apt update
sudo apt install -y git
```

If you are already root on a server, omit `sudo`. Your config and aliases will
belong to the user running setup: `/root` for root, not your other user accounts.
The installer supports Linux x86_64 and ARM64 and needs internet access.

### 2. Clone the configuration

If you already have a **different** Neovim configuration, back it up first:

```bash
mv "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim.backup-$(date +%s)"
```

Skip that command if the folder does not exist. Then clone:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"
git clone https://github.com/facelessuum/nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
cd "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
```

If this repo is already cloned, do not clone again. Instead:

```bash
cd "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
git pull
```

Commit or stash any local changes before pulling.

### 3. Install Neovim and register aliases

In **Bash**, from the checkout, run:

```bash
bash setup.sh && source ~/.bashrc
```

Run setup as your normal user, not `sudo bash setup.sh`; it requests sudo for
system installation when needed. Running as root is also supported.

Setup installs:

- Official Neovim **0.11.4** under `/opt`, linked as `/usr/local/bin/nvim`.
- Git, curl, certificates, tar, build tools, ripgrep, and jq through apt on
  Ubuntu/Debian. On other Linux distributions, install prerequisites yourself.
- The JSON alias loader in your `~/.bashrc`, including `e` for `nvim`.

Existing `/opt/nvim-linux-*` installations are backed up before replacement.
Your editor config, fonts, terminal preferences, and any Snap installation stay
untouched. Wakapi/WakaTime is not included. The `source ~/.bashrc` command
activates aliases in your current Bash session; alternatively, open a new terminal.

### 4. Open Neovim and wait for plugins

Run **in your terminal**:

```bash
nvim --version
nvim
```

The version should be **0.11.4 or newer**. On first launch, your config downloads
the plugin manager, installs plugins, and installs Treesitter parsers. Wait for
installation to finish. The Lazy installation window stays open so you can
review results—press **`q`** to close it when finished. Restart Neovim if prompted.
Your settings and keybindings load directly from this repo.

If `nvim` still launches an old version or reports a missing executable:

```bash
hash -r
/usr/local/bin/nvim
```

Ensure `/usr/local/bin` comes before `/snap/bin` or an older Neovim directory in
`PATH` if you want plain `nvim` to use this installation.

### 5. Optional editor tools and checks

The following are **Neovim commands, not terminal commands**. Open Neovim,
press **Esc**, type a command including its leading `:`, then press **Enter**:

```vim
:checkhealth
```

To install language servers or formatters, open Mason:

```vim
:Mason
```

For the Python completion and diagnostics configured here:

```vim
:MasonInstall pyright ty
```

External tools may require runtimes such as Node.js or Python. Install project
dependencies separately. System clipboard support needs a clipboard provider
(such as `xclip` on X11). Choose a Nerd Font in your terminal for plugin icons.
Aliases referencing `/home/umm`, Chrome, or VS Code must be customized for a
server without those paths/apps; edit `alias/aliases.json` and reload `~/.bashrc`.

### Copying settings to another machine

Commit and push your changes on the original machine, then follow steps 1–4 on
the new machine. Keep `lazy-lock.json` in Git. To explicitly restore its exact
plugin versions, run **inside Neovim**:

```vim
:Lazy restore
```

This is optional for normal startup; plugins already install automatically.

### Already have Neovim / using macOS?

You can skip `setup.sh` if Neovim **0.11.4+**, Git, make, a C compiler (`cc`),
tar, and curl are already installed. On macOS, install these with your preferred
package manager; the script is Linux-only. Follow step 2, then run `nvim`.
For Bash aliases without reinstalling Neovim, install `jq` separately and run:

```bash
bash alias/setup_alias_loader.sh && source ~/.bashrc
```

## Keybindings

**Normal** is the neutral/navigation mode; press `Esc` to leave Insert mode.
**Visual** selects text. **Terminal** sends input to the embedded shell.
The leader key is **Space**. A `+` means hold the keys together; `jk`, `gg`,
and `Space`, then `B` are sequences. Letter keys are lowercase unless Shift
or an uppercase letter is explicitly shown.

These tables cover the configured shortcuts and the enabled picker/completion
plugin bindings. Standard Neovim editing commands still apply unless overridden.
Plugin-local mappings take priority: for example, Alt+D moves the cursor in an
editor, opens a right split in Telescope, and cycles sessions in the terminal.

### Editor and navigation

| Shortcut | Mode | Action |
| --- | --- | --- |
| `;` | Normal | Open the command line, like `:` |
| `jk` | Insert | Return to Normal mode |
| Alt+W / Alt+A / Alt+S / Alt+D | Normal, Insert, Visual | Move cursor up / left / down / right |
| Alt+Shift+W / Alt+Shift+A / Alt+Shift+S / Alt+Shift+D | Normal, Insert, Visual | Focus split above / left / below / right; finish Visual selection first |
| Ctrl+W | Normal, Insert, Visual, Terminal | Immediately close current split; close its tab if it is the last split; exit Neovim if it is the final window; confirm unsaved changes |
| `n` | Normal | Next tab |
| Ctrl+K | Normal, Insert | Next tab; completion signature help can take priority in Insert mode |
| Ctrl+Q | Normal, Insert | **Force-close the current tab**, potentially discarding unsaved changes |
| Ctrl+E | Normal, Insert | Find files with Telescope; completion cancellation can take priority in Insert mode |
| Space, then `b` | Normal | Search open buffers with Telescope |
| Alt+L | Normal, Insert, Visual | Search all text in the current file, including names and values |
| Ctrl+F | Normal, Insert | Toggle the file tree and reveal the current file; completion documentation scrolling can take priority in Insert mode |
| Alt+Enter | Normal, Insert | Go to definition of the symbol under the cursor using the language server |
| Ctrl+C | Normal, Insert | Copy the current line to the system clipboard and enter Insert mode |
| Ctrl+X | Normal, Insert | Cut the current line and enter Insert mode |
| Ctrl+V | Normal, Insert | Paste from the system clipboard and enter Insert mode |
| Ctrl+Z | Normal, Insert | Undo and enter Insert mode |
| Ctrl+Y | Normal, Insert | Redo |
| Shift+Tab | Normal, Insert, Visual | Unindent line or selection |
| Ctrl+R | Normal, Insert, Visual | Delete the whole word under the cursor (Visual selection ends first) |
| Alt+F | Normal, Insert, Visual | Format current file or selected range |
| Alt+Q / Alt+E | Normal, Insert | Duplicate line below / above |
| Alt+J / Alt+K | Normal, Insert | Move line up / down |
| Shift+Up / Shift+Down | Visual | Move selected lines up / down |
| `c` / Shift+C | Visual | Yank selection / selected lines |
| `d` / Shift+D | Visual | Delete selection / selected lines |

Alt+W and Alt+S land at the beginning of the adjacent line when leaving a blank
line. Ordinary arrow keys retain their usual movement.

Ctrl+W replaces Neovim's usual window-command prefix. To create splits without
Telescope, use `:vsplit` (side by side) or `:split` (above/below).
Copy, cut, and paste use the system clipboard (`unnamedplus`), including Visual
mode `c`, Ctrl+C, and normal yanks. Linux needs a clipboard provider such as
`xclip` (install separately on X11). To copy terminal output, press Ctrl+\ then
Ctrl+N, select lines with `V` and the arrow keys, then press Ctrl+C or `y`.
Press `i` to resume shell input. Ctrl+C in shell input mode still interrupts
the command.

### Telescope: search and open files

Telescope file search includes dotfiles but respects `.gitignore`, including in
folders without a Git repository. `.env`, `.env.*`, and `.envrc` are exceptions
and remain searchable. It requires `ripgrep` (`rg`), installed separately.

These shortcuts apply inside the picker. Enter switches to an existing tab
when the selected file is already displayed, or opens a new tab otherwise. Directional splits are placed
relative to the editing window from which the picker was opened. Enter and the
directional split shortcuts enter Insert mode in the destination file.
Alt+L is the exception to the new-tab behavior: Enter jumps to the selected
line in the current file. All text is searchable, including names and values.

| Shortcut | Picker mode | Action |
| --- | --- | --- |
| Enter | Insert, Normal | Switch to existing file tab, or open a new tab |
| Alt+W / Alt+A / Alt+S / Alt+D | Insert, Normal | Open selection in a split above / left / below / right |
| Alt+Enter | Insert, Normal | Open selection in a vertical split |
| Ctrl+Enter | Insert, Normal | Vertical split, only in terminals that send it distinctly from Enter |
| Up / Down | Insert, Normal | Previous / next result |
| Ctrl+P / Ctrl+N | Insert | Previous / next result |
| `k` / `j` | Normal | Previous / next result |
| Ctrl+X / Ctrl+V / Ctrl+T | Insert, Normal | Horizontal split / vertical split / new tab |
| Ctrl+A | Insert | Select all search text; Backspace clears it |
| Ctrl+C | Insert | Close picker |
| Esc | Insert, then Normal | Leave prompt typing mode; press again to close picker |
| Tab / Shift+Tab | Insert, Normal | Toggle selection and move to the next / previous result |
| Ctrl+U / Ctrl+D | Insert, Normal | Scroll preview up / down |
| Ctrl+F / Ctrl+K | Insert, Normal | Scroll preview left / right |
| PageUp / PageDown | Insert, Normal | Scroll results up / down |
| Alt+F / Alt+K | Insert, Normal | Scroll results left / right |
| Ctrl+Q | Insert, Normal | Send results to the quickfix list and open it |
| Alt+Q | Insert, Normal | Send marked results to the quickfix list and open it |
| Ctrl+L | Insert | Complete tag in the query |
| Ctrl+/ | Insert | Show picker shortcut help; Ctrl+_ is an equivalent terminal encoding |
| `?` | Normal | Show picker shortcut help |
| `gg` / Shift+G | Normal | First / last result |
| Shift+H / Shift+M / Shift+L | Normal | Top / middle / bottom of results |
| Ctrl+W | Insert | Delete the previous word in the search prompt (picker-local override) |
| Ctrl+R, then Ctrl+W / Ctrl+A / Ctrl+F / Ctrl+L | Insert | Insert original editor word / WORD / filename / line into query |
| Ctrl+J | Insert | No action; Telescope blocks newlines in its prompt |
| Left-click / double-click | Insert, Normal | Select / open a result using the picker's mouse action |

GNOME Terminal 3.52/VTE 0.76 sends Ctrl+Enter as plain Enter. Use Alt+Enter or the
directional Alt shortcuts there. The native fzf matcher handles sorting; previews
skip files larger than 0.5 MB and syntax highlighting above 0.1 MB.

### Completion and snippets

These are Blink's Insert-mode bindings; snippet jumping also applies inside
snippet placeholders. Simply browsing suggestions does **not** insert their text.

| Shortcut | Action |
| --- | --- |
| Tab | Accept selected/first completion; otherwise jump to next snippet placeholder, then fall back to Tab |
| Enter | Accept selected completion; otherwise normal Enter |
| Ctrl+Y | Accept selected/first completion |
| Shift+Tab | Previous snippet placeholder |
| Up / Down, Ctrl+P / Ctrl+N | Previous / next completion |
| Ctrl+Space | Show completion, then show/hide documentation |
| Ctrl+E | Cancel completion; fall back to the editor mapping when not handled |
| Ctrl+B / Ctrl+F | Scroll documentation up / down |
| Ctrl+K | Show/hide signature help, falling back when not handled |

### Multiple cursors

Use Ctrl+D to select the word, repeat Ctrl+D to select more occurrences, then
just type to replace every selection. No `c` or `i` is needed. Printable keys
(including letters such as `c`, `i`, and `a`) insert text while multicursor is
active. Selections remain unchanged until you type or delete; Esc cancels them.
Replacing a single selection exits multicursor and continues in regular Insert
mode; two or more selections keep multicursor active. Normal-mode mappings are
restored when the session ends. `^` remains a movement command until typing starts
because the plugin uses it internally when inserting newlines.

| Shortcut | Mode/context | Action |
| --- | --- | --- |
| Ctrl+D | Normal, Insert | Select the word; press again to add the next matching occurrence |
| Ctrl+D | Visual | Add the selected text through vim-visual-multi's subword mapping |
| Ctrl+L | Normal, Insert | Add the entire current line as an editable region |
| Ctrl+Shift+L | Normal, Insert, Visual | Select all matching occurrences, if the terminal sends this key distinctly |
| Alt+Click | Normal, Insert | Add a cursor at the clicked position |
| Typing | Multiple-cursor selections | Replace selections immediately; insert at empty cursors |
| Backspace / Delete | Multiple-cursor selections | Delete selections and start typing |
| Tab | Multiple-cursor Insert mode | Accept completion when visible; otherwise insert a tab |
| Up / Down | Multiple-cursor Insert mode | Browse completion when visible; otherwise move the cursors |
| Enter | Multiple-cursor Insert mode | Accept completion when available; otherwise insert a return at the cursors |
| Esc | Multiple-cursor editing | End multicursor editing with one press |
| Ctrl+Z | Multiple-cursor editing | Undo; keep multicursor with two or more selections, exit with one |
| Alt+W / Alt+A / Alt+S / Alt+D | Multiple-cursor editing | Move up / left / down / right and type; exit multicursor only when one selection/cursor remains |

### Embedded terminal

| Shortcut | Mode/context | Action |
| --- | --- | --- |
| Ctrl+J | Normal, Insert, Visual, Terminal | Toggle terminal panel; opening focuses the shell, hiding returns to editor Insert mode |
| Alt+N | Normal, Insert, Visual, Terminal | Create a terminal session |
| Alt+X | Normal, Insert, Visual, Terminal | Delete active session, or the session highlighted in the list |
| Alt+T | Normal, Insert, Visual, Terminal | Focus the terminal list |
| Alt+D | Terminal, terminal-buffer Normal/Visual, terminal list | Next terminal session |
| `n` | Terminal list | Create a session |
| Enter / double-click | Terminal list | Switch to highlighted session; the first row creates a session |
| `d` | Terminal list | Delete highlighted session |
| `q` | Terminal list | Hide panel |
| Ctrl+\, then Ctrl+N | Terminal | Leave shell input mode for terminal-buffer Normal mode |

Use Ctrl+J to hide the complete panel while keeping its shells alive. Closing
either panel window with Ctrl+W also hides the other half and retains the sessions.

### File tree

The tree hides dot folders (such as `.git` and `.venv`), while showing dotfiles
and other files/folders covered by `.gitignore`. Telescope file search excludes
ignored paths except for the environment-file exceptions above.

Press `n` in the tree to enter a name: names with an extension (such as `notes.md`
or `data.json`) create files; names without an extension create folders. The item
is created inside the selected folder, or beside the selected file. A trailing
`/` explicitly creates a folder, even if its name contains a dot.

Ctrl+E opens Telescope file search from the tree.

Ctrl+F toggles the tree. When opening it, parent folders expand and the cursor
focuses the current file, including files opened through Telescope. The tree root
updates if needed to reveal a file outside it. Existing filters still apply.
Its local mappings below override editor mappings while
it has focus. `s`, Enter, and double-click show the file and keep focus in the
tree; `o` opens its folder in the system file manager; `i` enters Insert mode in the editing
window. Folder selections expand/collapse with the file-opening shortcuts; `o` opens
them in the system file manager.

<details>
<summary>All active file-tree shortcuts (custom and inherited)</summary>

| Key (Neovim notation) | Mode | Action |
| --- | --- | --- |
| `-` | Normal | Up |
| `.` | Normal | Run Command |
| `<2-LeftMouse>` | Normal | Open file or toggle folder; stay in tree |
| `<2-RightMouse>` | Normal | CD |
| `<BS>` | Normal | Close Directory |
| `<C-E>` | Normal | Find files with Telescope |
| `<C-K>` | Normal | Info |
| `<C-R>` | Normal | Rename: Omit Filename |
| `<C-T>` | Normal | Open: New Tab |
| `<C-V>` | Normal | Open: Vertical Split |
| `<C-X>` | Normal | Open: Horizontal Split |
| `<C-]>` | Normal | CD |
| `<CR>` | Normal | Open file or toggle folder; stay in tree |
| `<Del>` | Normal | Delete |
| `<Del>` | Visual | Delete |
| `<Tab>` | Normal | Open Preview |
| `<lt>` | Normal | Previous Sibling |
| `>` | Normal | Next Sibling |
| `B` | Normal | Toggle Filter: No Buffer |
| `C` | Normal | Toggle Filter: Git Clean |
| `D` | Normal | Trash |
| `D` | Visual | Trash |
| `E` | Normal | Expand All |
| `F` | Normal | Live Filter: Clear |
| `H` | Normal | Toggle Filter: Dotfiles |
| `I` | Normal | Toggle Filter: Git Ignored |
| `J` | Normal | Last Sibling |
| `K` | Normal | First Sibling |
| `L` | Normal | Toggle Group Empty |
| `M` | Normal | Toggle Filter: No Bookmark |
| `O` | Normal | Open: No Window Picker |
| `P` | Normal | Parent Directory |
| `R` | Normal | Refresh |
| `S` | Normal | Search |
| `U` | Normal | Toggle Filter: Custom |
| `W` | Normal | Collapse All |
| `Y` | Normal | Copy Relative Path |
| `[c` | Normal | Prev Git |
| `[e` | Normal | Prev Diagnostic |
| `]c` | Normal | Next Git |
| `]e` | Normal | Next Diagnostic |
| `a` | Normal | Create File Or Directory |
| `bd` | Normal | Delete Bookmarked |
| `bmv` | Normal | Move Bookmarked |
| `bt` | Normal | Trash Bookmarked |
| `c` | Normal | Copy |
| `c` | Visual | Copy |
| `d` | Normal | Delete |
| `d` | Visual | Delete |
| `e` | Normal | Rename: Basename |
| `f` | Normal | Live Filter: Start |
| `g?` | Normal | Help |
| `ge` | Normal | Copy Basename |
| `gp` | Normal | Move |
| `gy` | Normal | Copy Absolute Path |
| `gy` | Visual | Copy Absolute Path |
| `i` | Normal | Return to file and insert |
| `m` | Normal | Toggle Bookmark |
| `m` | Visual | Toggle Bookmark |
| `o` | Normal | Open selected folder, or file’s containing folder, in system file manager |
| `p` | Normal | Paste |
| `q` | Normal | Close |
| `r` | Normal | Rename |
| `s` | Normal | Open file or toggle folder; stay in tree |
| `u` | Normal | Rename: Full Path |
| `x` | Normal | Cut |
| `x` | Visual | Cut |
| `y` | Normal | Copy Name |

</details>

### Go to definition

Place your cursor on a function, variable, or imported symbol and press
**Alt+Enter** to jump to its definition, including in another file. For example,
using a function in `useTest.py` can jump to its definition in `test.py`.
Press **Esc**, then **Ctrl+O** to return to the previous location.

This requires an attached language server that supports definition lookup.
For Python, install Pyright with `:MasonInstall pyright` and restart Neovim;
imports must be resolvable in your project's Python environment. Multiple
matches may open a location list. Inside Telescope, Alt+Enter retains its
existing vertical-split action. If your terminal intercepts Alt+Enter, disable
that terminal shortcut or use `:lua vim.lsp.buf.definition()` inside Neovim.

### Python completion and inline errors

ty supplies Python completion and indexed auto-imports; Pyright supplies inline
errors and the other language features. Install both separately through Mason.
For an existing setup, run `:MasonInstall pyright ty`. If system Python lacks
`ensurepip`, `uv tool install ty==0.0.78` installs ty without that dependency.
Restart Neovim after installing.

Type a name prefix, select the desired symbol, and accept with Tab or Enter to
insert both the name and its import. This covers public variables, functions,
async functions, classes, and constants from unopened project files, nested
packages, the standard library, and packages installed in the selected Python
environment. Editable sibling packages are included through that environment.
Initial indexing may take a few seconds; project exclusions still apply.
Importable modules must be on Python's search path. This does not search unrelated
virtual environments or expose function-local variables as module exports.
Dynamic exports without usable source or type stubs can still be incomplete.

The interpreter is selected from the project root's `.venv`, then `venv`,
searching parent folders up to and including the repository root for shared
monorepo environments. It then tries `VIRTUAL_ENV` or `CONDA_PREFIX` inherited
when Neovim starts, then Python on PATH.
Install libraries such as NumPy into that environment. Activating a virtual
environment inside the embedded terminal does not change Neovim's environment.
For another interpreter, use `:LspPyrightSetPythonPath /path/to/bin/python` in a
Python buffer; this updates both Pyright and ty. Restart Neovim after creating a new environment.
Python diagnostics default to open files with optional type checking off, matching
Pylance defaults. Undefined names, unresolved imports, and syntax errors still
appear. Project Pyright settings can enable stricter checking. Outdated versioned
diagnostic reports are ignored; current empty reports clear inline errors.

### JSON inline errors

Install the JSON language server with `:MasonInstall json-lsp`, then restart
Neovim. JSON and JSONC files show syntax errors inline as you edit, including
standalone files outside a project. Prettier formats JSON but does not provide
these diagnostics.

### Inline errors for other file types

Inline diagnostics are enabled globally, including while typing. Install the
servers for the languages you use, then restart Neovim:

| File types | Neovim install command |
| --- | --- |
| JavaScript / TypeScript / JSX / TSX | `:MasonInstall typescript-language-server` |
| Lua | `:MasonInstall lua-language-server` |
| HTML | `:MasonInstall html-lsp` |
| CSS / SCSS / Less | `:MasonInstall css-lsp` |
| YAML | `:MasonInstall yaml-language-server` |
| TOML | `:MasonInstall taplo` |
| Shell scripts | `:MasonInstall bash-language-server shellcheck` |
| Markdown | `:MasonInstall marksman` |
| Go | `:MasonInstall gopls` |
| Rust | `:MasonInstall rust-analyzer` |
| C / C++ | `:MasonInstall clangd` |
| PHP | `:MasonInstall intelephense` |
| Ruby | `:MasonInstall ruby-lsp` |

Diagnostics depend on the server: Markdown mainly checks links, not prose;
HTML is not a comprehensive HTML validator. ShellCheck supplies shell linting
through the Bash server. Some servers require project roots, dependencies, or
language toolchains (for example Go, Rust, and Ruby). C/C++ projects may need
`compile_commands.json` for accurate results. Use `:checkhealth vim.lsp` to
check server availability and attachment. File types not listed here or in the
Python/JSON sections need additional language-specific setup.

### Configuration locations

Editor shortcuts live in `lua/core/keymaps.lua`. Terminal shortcuts live in
`lua/core/terminal.lua`; Telescope, file tree, formatting, and completion shortcuts
live with their respective configurations in `lua/plugins/`.
