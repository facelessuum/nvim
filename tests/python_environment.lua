-- Run from the config directory:
-- nvim --headless -u NONE -l tests/python_environment.lua
package.path = "./lua/?.lua;" .. package.path
local environment = require("core.python_environment")
local root = vim.fn.tempname()
local previous = { virtual = vim.env.VIRTUAL_ENV, conda = vim.env.CONDA_PREFIX }

local function interpreter(directory, suffix)
  local path = directory .. (suffix or "/bin/python")
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ "#!/bin/sh", "exit 0" }, path)
  assert(vim.fn.setfperm(path, "rwx------") == 1)
  return path
end

local ok, err = xpcall(function()
  local project = root .. "/project"
  local member = project .. "/packages/member"
  vim.fn.mkdir(project .. "/.git", "p")
  vim.fn.mkdir(member, "p")
  vim.env.VIRTUAL_ENV = root .. "/activated"
  vim.env.CONDA_PREFIX = root .. "/conda"
  local activated = interpreter(vim.env.VIRTUAL_ENV)
  local conda = interpreter(vim.env.CONDA_PREFIX)
  assert(environment.find(member) == activated, "virtual environment wins over Conda")

  local shared = interpreter(project .. "/.venv")
  local nearest = interpreter(member .. "/venv")
  local uv = interpreter(member .. "/.venv")
  assert(environment.find(member) == activated, "activated virtual environment wins over project environments")
  vim.env.VIRTUAL_ENV = nil
  assert(environment.find(member) == conda, "activated Conda environment wins over project environments")
  vim.env.CONDA_PREFIX = root .. "/another-conda"
  local another_conda = interpreter(vim.env.CONDA_PREFIX)
  assert(environment.find(member) == another_conda, "environment selection is not cached")
  vim.env.VIRTUAL_ENV = root .. "/missing"
  assert(environment.find(member) == another_conda, "invalid virtual environment falls back to Conda")
  vim.env.CONDA_PREFIX = root .. "/also-missing"
  assert(environment.find(member) == uv, "invalid activated environments fall back to project environment")
  vim.env.VIRTUAL_ENV = ""
  vim.env.CONDA_PREFIX = ""
  assert(environment.find(member) == uv, "empty environment variables are ignored; .venv wins over venv")
  vim.fn.delete(member .. "/.venv", "rf")
  assert(environment.find(member) == nearest, "nearest environment wins without an activated environment")
  vim.fn.delete(member .. "/venv", "rf")
  assert(environment.find(member) == shared, "shared monorepo environment fallback")
  vim.env.VIRTUAL_ENV = root .. "/activated"
  vim.env.CONDA_PREFIX = root .. "/conda"

  vim.fn.delete(member .. "/.venv", "rf")
  vim.fn.delete(member .. "/venv", "rf")
  vim.fn.delete(project .. "/.venv", "rf")
  interpreter(root .. "/.venv")
  assert(environment.find(member) == activated, "do not search beyond the repository boundary")
  vim.env.VIRTUAL_ENV = nil
  assert(environment.find(member) == conda, "Conda fallback")
  vim.env.CONDA_PREFIX = nil
  local system = vim.fn.exepath("python3")
  if system == "" then system = vim.fn.exepath("python") end
  assert(environment.find(member) == (system ~= "" and system or nil), "system interpreter fallback")

  local windows = interpreter(member .. "/.venv", "/Scripts/python.exe")
  assert(environment.find(member) == windows, "Windows virtual environment layout")
end, debug.traceback)

vim.env.VIRTUAL_ENV = previous.virtual
vim.env.CONDA_PREFIX = previous.conda
vim.fn.delete(root, "rf")
if not ok then error(err) end
print("Python environment selection: passed")
