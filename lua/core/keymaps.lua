local map = vim.keymap.set

-- General
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Arrow key mappings
local function vertical_move(direction, edge, step)
  return function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    if vim.bo.buftype == "" and not vim.b.visual_multi
      and vim.api.nvim_get_current_line():match("^%s*$")
      and row + step >= 1 and row + step <= vim.api.nvim_buf_line_count(0) then
      return direction .. edge
    end
    return direction
  end
end
map({ "n", "i", "x" }, "<A-w>", vertical_move("<Up>", "<Home>", -1), {
  expr = true, desc = "Move up; line beginning when leaving a blank line",
})
map({ "n", "i", "x" }, "<A-s>", vertical_move("<Down>", "<Home>", 1), {
  expr = true, desc = "Move down; line beginning when leaving a blank line",
})
map({"n", "i", "x"}, "<A-a>", "<Left>", { desc = "Move left" })
map({"n", "i", "x"}, "<A-d>", "<Right>", { desc = "Move right" })

-- Alt+Shift sends Alt with an uppercase letter in terminal Neovim.
-- Finish Visual selection before moving into another split.
for _, binding in ipairs({
  { "W", "k", "above" },
  { "A", "h", "left" },
  { "S", "j", "below" },
  { "D", "l", "right" },
}) do
  local key = "<A-" .. binding[1] .. ">"
  local command = "<cmd>wincmd " .. binding[2] .. "<CR>"
  map({ "n", "i" }, key, command, { silent = true, desc = "Focus split " .. binding[3] })
  map("x", key, "<Esc>" .. command, { silent = true, desc = "Focus split " .. binding[3] })
end

-- Shortcuts

-- Navigation
map({ "n", "i" }, "<A-CR>", vim.lsp.buf.definition, {
  desc = "Go to definition of symbol under cursor",
})
map({"n", "i"}, "<C-c>", "<ESC>yyi", { desc = "Copy" })
map({"n", "i"}, "<C-x>", "<ESC>ddi", { desc = "Cut" })
map({"n", "i"}, "<C-v>", "<ESC>pi", { desc = "Paste" })
map({"n", "i"}, "<C-z>", "<ESC>ui", { desc = "Undo" })

-- Use the built-in redo command even though Ctrl+R is mapped below.
map("n", "<C-y>", "<C-r>", { desc = "Redo" })
map("i", "<C-y>", "<C-o><C-r>", { desc = "Redo" })

-- Delete the whole word under the cursor.
map("n", "<C-r>", "diw", { desc = "Delete word" })
map("i", "<C-r>", "<C-o>diw", { desc = "Delete word" })
map("x", "<C-r>", "<Esc>diw", { desc = "Delete word" })

-- Select the entire buffer from Normal or Insert mode.
map({ "n", "i" }, "<C-a>", "<Esc>ggVG", { desc = "Select all lines" })

-- Lines Shortcuts
map("n", "<S-Tab>", "<<", { desc = "Unindent line" })
map("i", "<S-Tab>", "<C-d>", { desc = "Unindent line" })
map("x", "<S-Tab>", "<gv", { desc = "Unindent selection" })
map({"n", "i"}, "<A-q>", "<ESC>mzyyp`zi", { desc = "Duplicate line below" })
map({"n", "i"}, "<A-e>", "<ESC>mzyyP`zi", { desc = "Duplicate line above" })
map({"n", "i"}, "<A-j>", "<ESC>:move .-2<CR>i", { desc = "Move line up" })
map({"n", "i"}, "<A-k>", "<ESC>:move .+1<CR>i", { desc = "Move line down" })
map("x", "<S-Up>", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })
map("x", "<S-Down>", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })

-- Copy/Delete Visual Mode
map("x", "<C-c>", "y", { desc = "Copy selection to clipboard" })
map({"x"}, "c", "y", { desc="Copy In Visual Mode Highlight"})
map({"x"}, "C", "Y", { desc="Copy In Visual Mode Highlight"})
map({"x"}, "D", "D", { desc="Delete In Visual Mode Highlight"})
map({"x"}, "d", "d", { desc="Delete In Visual Mode Highlight"})

-- Tabs
map("n", "n", "gt", { desc = "Next tab" })
map({"n","i"}, "<C-k>", "<cmd>tabnext<cr>", { desc = "Next tab" })
map({"n", "i"}, "<C-q>", "<cmd>tabclose!<cr>", { desc = "Force close tab" })

-- :quit closes the focused window, or its tab when it is the last window.
-- Confirm protects unsaved edits; closing the final window exits Neovim.
for _, mode in ipairs({ "n", "i", "x", "t" }) do
  local leave = mode == "t" and "<C-\\><C-n>" or (mode == "x" and "<Esc>" or "")
  map(mode, "<C-w>", leave .. "<cmd>confirm quit<CR>", {
    silent = true,
    nowait = true, -- Do not wait for longer Ctrl+W mappings.
    desc = "Close current split or tab",
  })
end
