-- Run from the config directory with nvim-lspconfig, blink.cmp and Pyright installed:
-- nvim --headless -u NONE -l tests/lsp_diagnostics.lua
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/nvim-lspconfig")
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/blink.cmp")
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
package.path = "./lua/?.lua;" .. package.path
assert(vim.fn.executable("pyright-langserver") == 1, "Install Pyright with :MasonInstall pyright")
require("core.diagnostics")
require("plugins.lsp")

local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
vim.fn.writefile({ "{}" }, root .. "/pyrightconfig.json")
vim.fn.writefile({ 'value: int = "wrong"' }, root .. "/main.py")

local ok, err = xpcall(function()
  vim.cmd.edit(root .. "/main.py")
  vim.bo.filetype = "python"
  local buf = vim.api.nvim_get_current_buf()
  local module = root .. "/newly_created_module.py"
  local function wait_for(code, present, message)
    assert(vim.wait(15000, function()
      local found = false
      for _, diagnostic in ipairs(vim.diagnostic.get(buf)) do
        if diagnostic.code == code then found = true end
      end
      return found == present
    end, 50), message .. ": " .. vim.inspect(vim.diagnostic.get(buf)))
  end

  wait_for("reportAssignmentType", true, "initial type error")
  local client_id = vim.lsp.get_clients({ bufnr = buf, name = "pyright" })[1].id
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "value: int = 1" })
  wait_for("reportAssignmentType", false, "fixed type error clears without saving")
  assert(vim.bo[buf].modified, "test unsaved live updates, not save-triggered diagnostics")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "from newly_created_module import value",
    "result: int = value",
  })
  wait_for("reportMissingImports", true, "initial unresolved import")
  vim.fn.writefile({ "value = 1" }, module)
  wait_for("reportMissingImports", false, "external module creation clears unresolved import")

  vim.fn.writefile({ 'value = "wrong"' }, module)
  wait_for("reportAssignmentType", true, "external module edits update dependent diagnostics")
  vim.fn.writefile({ "value = 1" }, module)
  wait_for("reportAssignmentType", false, "fixing external module clears dependent error")

  vim.fn.delete(module)
  wait_for("reportMissingImports", true, "external module deletion reports unresolved import")
  vim.fn.writefile({ "value = 1" }, module)
  wait_for("reportMissingImports", false, "recreating external module clears unresolved import")
  assert(#vim.diagnostic.get(buf) == 0, "all diagnostics cleared without restarting the server")
  local clients = vim.lsp.get_clients({ bufnr = buf, name = "pyright" })
  assert(#clients == 1 and clients[1].id == client_id, "keep the same language server throughout")
end, debug.traceback)

for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
vim.cmd("silent! %bwipeout!")
vim.fn.delete(root, "rf")
if not ok then error(err) end
print("Live LSP diagnostics and external import updates: passed")
