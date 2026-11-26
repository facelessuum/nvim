-- Refresh visible files changed by another tool, even while Neovim is idle.
vim.opt.autoread = true
local reload_group = vim.api.nvim_create_augroup("AutoRead", { clear = true })
local function refresh_visible_files()
  local mode = vim.api.nvim_get_mode().mode
  if mode:match("^[cRr!t]") then return end
  local checked = {}
  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(window)
    local opts = vim.bo[buf]
    if not checked[buf] and opts.buftype == "" and not opts.modified and vim.api.nvim_buf_get_name(buf) ~= "" then
      checked[buf] = true
      vim.cmd.checktime(buf)
    end
  end
end

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = reload_group,
  callback = function() vim.schedule(refresh_visible_files) end,
})
local reload_timer = assert(vim.uv.new_timer())
reload_timer:start(1000, 1000, vim.schedule_wrap(refresh_visible_files))
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = reload_group,
  once = true,
  callback = function() reload_timer:close() end,
})

-- Save each buffer after typing has paused for 500 ms.
local group = vim.api.nvim_create_augroup("AutoSave", { clear = true })
local pending = {}

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
  group = group,
  callback = function(event)
    local buf = event.buf
    local request = {}
    pending[buf] = request

    vim.defer_fn(function()
      if pending[buf] ~= request then
        return
      end
      pending[buf] = nil

      if not vim.api.nvim_buf_is_loaded(buf) then
        return
      end

      local opts = vim.bo[buf]
      local name = vim.api.nvim_buf_get_name(buf)
      if opts.buftype ~= "" or not opts.modifiable or opts.readonly or not opts.modified or name == "" then
        return
      end

      local writable = vim.fn.filewritable(name) == 1
      if vim.fn.getftype(name) == "" then
        writable = vim.fn.filewritable(vim.fn.fnamemodify(name, ":h")) == 2
      end
      if not writable then
        vim.notify("Autosave skipped: file is not writable: " .. name, vim.log.levels.WARN)
        return
      end

      local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd("silent update")
      end)
      if not ok then
        vim.notify("Autosave failed for " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
      end
    end, 500)
  end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(event)
    pending[event.buf] = nil
  end,
})
