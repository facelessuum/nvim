-- Prefer activated environments, then the nearest project or shared monorepo environment.
local M = {}

function M.find(root)
  root = root or vim.fn.getcwd()
  local environments = {}
  -- Explicit shell activation takes priority over an existing project .venv.
  for _, variable in ipairs({ "VIRTUAL_ENV", "CONDA_PREFIX" }) do
    local environment = vim.env[variable]
    if environment and environment ~= "" then
      table.insert(environments, environment)
    end
  end
  -- Workspace members can share a virtual environment at the monorepo root.
  local directory = root
  while directory do
    table.insert(environments, directory .. "/.venv")
    table.insert(environments, directory .. "/venv")
    if vim.uv.fs_stat(directory .. "/.git") then break end
    local parent = vim.fs.dirname(directory)
    if parent == directory then break end
    directory = parent
  end
  for _, environment in ipairs(environments) do
    for _, suffix in ipairs({ "/bin/python", "/Scripts/python.exe", "/python.exe" }) do
      local executable = environment .. suffix
      if vim.fn.executable(executable) == 1 then return executable end
    end
  end
  local executable = vim.fn.exepath("python3")
  if executable == "" then executable = vim.fn.exepath("python") end
  if executable ~= "" then return executable end
end

return M
