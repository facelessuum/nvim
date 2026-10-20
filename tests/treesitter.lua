-- Run from the config directory (uses Neovim's bundled Lua parser):
-- nvim --headless -u NONE -l tests/treesitter.lua
package.path = "./lua/?.lua;" .. package.path

-- The configuration must not depend on either version of the plugin's API.
for _, module in ipairs({ "nvim-treesitter.configs", "nvim-treesitter" }) do
  package.preload[module] = function()
    error("Treesitter highlighting must not require " .. module)
  end
end

require("plugins.treesitter")
-- Reloading the configuration must not duplicate the FileType handler.
package.loaded["plugins.treesitter"] = nil
require("plugins.treesitter")
assert(#vim.api.nvim_get_autocmds({ group = "TreesitterHighlight" }) == 1, "one FileType handler")

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local value = 1" })
vim.bo[buf].filetype = "lua"
assert(vim.treesitter.highlighter.active[buf], "start native highlighting for Lua")

local unsupported = vim.api.nvim_create_buf(false, true)
vim.bo[unsupported].filetype = "no_such_treesitter_language"
assert(not vim.treesitter.highlighter.active[unsupported], "skip filetypes without parsers")
assert(vim.v.errmsg == "", "missing parsers must not cause startup errors")

vim.api.nvim_buf_delete(buf, { force = true })
vim.api.nvim_buf_delete(unsupported, { force = true })
print("Native Treesitter highlighting: passed")
