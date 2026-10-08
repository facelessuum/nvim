-- Run from the config directory with nvim-tree installed:
-- nvim --headless -u NONE -l tests/file_tree_split.lua
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/nvim-tree.lua")
package.path = "./lua/?.lua;" .. package.path
vim.o.columns = 180
require("plugins.nerdtree")

local api = require("nvim-tree.api")
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
local original = root .. "/original.txt"
local selected = root .. "/selected.txt"
vim.fn.writefile({ "original" }, original)
vim.fn.writefile({ "selected" }, selected)

local ok, err = xpcall(function()
  vim.cmd.edit(original)
  local editor = vim.api.nvim_get_current_win()
  api.tree.open({ path = root })
  api.tree.find_file({ buf = selected, open = true, focus = true })
  local tree = vim.api.nvim_get_current_win()
  assert(api.tree.get_node_under_cursor().absolute_path == selected, "selected file in tree")
  local mapping = vim.fn.maparg("<C-s>", "n", false, true)
  assert(mapping.buffer == 1 and type(mapping.callback) == "function", "tree-local Ctrl+S mapping")

  -- Both option values must produce the same layout without changing the option.
  for _, splitright in ipairs({ false, true }) do
    vim.o.splitright = splitright
    mapping.callback()
    assert(vim.o.splitright == splitright, "restore splitright")
    assert(vim.api.nvim_get_current_win() == tree, "keep focus in tree")
    assert(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(editor)) == original, "preserve original file")
    local opened
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == selected then opened = win end
    end
    assert(opened, "selected file opened")
    assert(#vim.api.nvim_tabpage_list_wins(0) == 3, "create one extra split")
    local editor_col = vim.api.nvim_win_get_position(editor)[2]
    local opened_col = vim.api.nvim_win_get_position(opened)[2]
    local tree_col = vim.api.nvim_win_get_position(tree)[2]
    assert(editor_col < opened_col and opened_col < tree_col, "original | selected | tree layout")
    vim.api.nvim_win_close(opened, true)
  end
end, debug.traceback)

api.tree.close()
vim.cmd("silent! %bwipeout!")
vim.fn.delete(root, "rf")
if not ok then error(err) end
print("File tree Ctrl+S split: passed")
