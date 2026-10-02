vim.g.mapleader = " "     -- Set leader to space (most common)

-- Render the theme palette accurately in true-color terminals.
vim.opt.termguicolors = true

-- Basic quality of life settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
-- Share copies, cuts, and pastes with desktop applications.
vim.opt.clipboard = "unnamedplus"
-- Over SSH or on headless servers, copy through the terminal (OSC 52) instead.
if require("core.platform").clipboard() == "osc52" then
  local osc52 = require("vim.ui.clipboard.osc52")
  -- Many terminals refuse OSC 52 reads, so paste Neovim's own last copy.
  local last = { {}, "v" }
  local function copy(register)
    local send = osc52.copy(register)
    return function(lines, regtype)
      last = { lines, regtype }
      send(lines, regtype)
    end
  end
  local function paste() return last end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
-- Let arrow keys (including Alt+A/D) cross line boundaries in all editing modes.
vim.opt.whichwrap:append("<,>,[,]")
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Dotenv variants use the installed Bash parser and shell syntax highlighting.
vim.filetype.add({
  filename = { [".env"] = "sh" },
  pattern = { ["%.env%..+"] = "sh" },
})
