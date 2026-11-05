-- Run from the config directory with nvim-lspconfig, blink.cmp and Pyright installed:
-- nvim --headless -u NONE -l tests/python_lsp_environment.lua
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/nvim-lspconfig")
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/blink.cmp")
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
package.path = "./lua/?.lua;" .. package.path
assert(vim.fn.executable("pyright-langserver") == 1, "Install Pyright with :MasonInstall pyright")
require("plugins.lsp")

local root = vim.fn.tempname()
local previous = { virtual = vim.env.VIRTUAL_ENV, conda = vim.env.CONDA_PREFIX }
local function run(command)
  local result = vim.system(command, { text = true }):wait(30000)
  assert(result.code == 0, vim.inspect(command) .. ": " .. (result.stderr or ""))
  return vim.trim(result.stdout or "")
end

local ok, err = xpcall(function()
  local project = root .. "/project"
  local conda = root .. "/conda"
  local python = vim.fn.exepath("python3")
  assert(python ~= "", "Python 3 with venv support is required")
  vim.fn.mkdir(project, "p")
  run({ python, "-m", "venv", "--without-pip", project .. "/.venv" })
  -- A regular venv has the same interpreter/site-packages layout as Conda here.
  run({ python, "-m", "venv", "--without-pip", conda })
  local executable = conda .. "/bin/python"
  local packages = run({ executable, "-c", "import sysconfig; print(sysconfig.get_path('purelib'))" })
  vim.fn.writefile({ "value: int = 1" }, packages .. "/nvim_environment_probe.py")
  vim.fn.writefile({ "{}" }, project .. "/pyrightconfig.json")
  vim.fn.writefile({ "from nvim_environment_probe import value", "result: str = value" }, project .. "/main.py")
  vim.env.VIRTUAL_ENV = nil
  vim.env.CONDA_PREFIX = conda

  vim.cmd.edit(project .. "/main.py")
  vim.bo.filetype = "python"
  local buffer = vim.api.nvim_get_current_buf()
  assert(vim.wait(15000, function()
    for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
      if diagnostic.code == "reportAssignmentType" then return true end
    end
    return false
  end, 50), "Pyright must resolve and type-check a package available only in the activated environment: "
    .. vim.inspect(vim.diagnostic.get(buffer)))
  local client = vim.lsp.get_clients({ bufnr = buffer, name = "pyright" })[1]
  assert(client.config.settings.python.pythonPath == executable, "Pyright must use activated Conda over .venv")
  for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
    assert(diagnostic.code ~= "reportMissingImports", "activated environment imports must resolve")
  end
  vim.api.nvim_buf_set_lines(buffer, 1, 2, false, { "result: int = value" })
  assert(vim.wait(15000, function()
    return #vim.diagnostic.get(buffer) == 0
  end, 50), "correctly typed import must clear all diagnostics")
end, debug.traceback)

for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
vim.cmd("silent! %bwipeout!")
vim.env.VIRTUAL_ENV = previous.virtual
vim.env.CONDA_PREFIX = previous.conda
vim.fn.delete(root, "rf")
if not ok then error(err) end
print("Pyright activated environment import resolution: passed")
