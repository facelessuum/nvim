-- Run from the config directory:
-- nvim --headless -u NONE -l tests/python_environment.lua
package.path = "./lua/?.lua;" .. package.path
local environment = require("core.python_environment")
local root = vim.fn.tempname()
local previous = {
  virtual = vim.env.VIRTUAL_ENV, conda = vim.env.CONDA_PREFIX,
  conda_default = vim.env.CONDA_DEFAULT_ENV, conda_exe = vim.env.CONDA_EXE,
}

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
  vim.env.CONDA_DEFAULT_ENV = nil
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

  local declared_prefix = root .. "/installed/workspace"
  local declared = interpreter(declared_prefix)
  local info = vim.json.encode({ root_prefix = root .. "/conda", envs = { declared_prefix } })
  local conda_exe = root .. "/fake-conda"
  local calls = root .. "/conda-calls"
  vim.fn.writefile({
    "#!/bin/sh",
    "echo called >> " .. vim.fn.shellescape(calls),
    "printf '%s\\n' " .. vim.fn.shellescape(info),
  }, conda_exe)
  assert(vim.fn.setfperm(conda_exe, "rwx------") == 1)
  vim.env.CONDA_EXE = conda_exe
  vim.fn.writefile({ 'name: "workspace" # editor dependencies', "dependencies: []" }, project .. "/environment.yaml")
  vim.fn.writefile({ "name: missing" }, member .. "/environment.yml")
  assert(environment.find(member) == declared, "discover ancestor Conda when the nearest declaration is unavailable")
  assert(#vim.fn.readfile(calls) == 1, "query Conda only once per lookup")
  vim.env.CONDA_PREFIX, vim.env.CONDA_DEFAULT_ENV = root .. "/conda", "base"
  assert(environment.find(member) == declared, "automatic base activation does not hide a declared environment")
  vim.env.CONDA_DEFAULT_ENV = "manual"
  assert(environment.find(member) == conda, "non-base activation overrides automatic discovery")
  vim.env.CONDA_PREFIX, vim.env.CONDA_DEFAULT_ENV = nil, nil
  local windows = interpreter(member .. "/.venv", "/Scripts/python.exe")
  assert(environment.find(member) == windows, "Windows virtual environment layout")
end, debug.traceback)

vim.env.VIRTUAL_ENV = previous.virtual
vim.env.CONDA_PREFIX = previous.conda
vim.env.CONDA_DEFAULT_ENV = previous.conda_default
vim.env.CONDA_EXE = previous.conda_exe
vim.fn.delete(root, "rf")
if not ok then error(err) end
print("Python environment selection: passed")
