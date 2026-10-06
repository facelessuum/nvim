vim.g.mapleader = " "     -- Set leader to space (most common)

-- Render the theme palette accurately in true-color terminals.
vim.opt.termguicolors = true

-- Basic quality of life settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
-- Share copies, cuts, and pastes with desktop applications.
vim.opt.clipboard = "unnamedplus"
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
