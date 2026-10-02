-- Parsers are compiled locally: needs git or curl+tar, and a C compiler (cc/gcc/clang).
local compilers = require("core.platform").compilers()
local has_compiler = #compilers > 0
if has_compiler then require("nvim-treesitter.install").compilers = compilers end
-- Do not start downloads/compilation during headless checks or scripted edits.
local can_install = has_compiler and #vim.api.nvim_list_uis() > 0

require("nvim-treesitter.configs").setup({
  ensure_installed = not can_install and {} or { "lua", "vim", "vimdoc", "query", "javascript", "typescript", "python", "bash", "json", "html", "css" },
  -- Skip compiling on machines without a compiler instead of erroring on every file.
  auto_install = can_install,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
})
