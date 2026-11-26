-- Resolve the Python interpreter for each Pyright workspace.
local M = {}

local function interpreter(prefix)
  if not prefix or prefix == "" then return end
  for _, suffix in ipairs({ "/bin/python", "/Scripts/python.exe", "/python.exe" }) do
    local executable = prefix .. suffix
    if vim.fn.executable(executable) == 1 then return executable end
  end
end

local function conda_command()
  local configured = vim.env.CONDA_EXE
  if configured and vim.fn.executable(configured) == 1 then return configured end
  local on_path = vim.fn.exepath("conda")
  if on_path ~= "" then return on_path end
  local home = vim.uv.os_homedir()
  if not home then return end
  for _, installation in ipairs({ "miniforge3", "miniconda3", "anaconda3" }) do
    for _, suffix in ipairs({ "/bin/conda", "/Scripts/conda.exe" }) do
      local executable = home .. "/" .. installation .. suffix
      if vim.fn.executable(executable) == 1 then return executable end
    end
  end
end

local function conda_info()
  local conda = conda_command()
  if not conda then return end
  local ok, result = pcall(function()
    return vim.system({ conda, "info", "--json" }, { text = true }):wait(3000)
  end)
  if not ok or result.code ~= 0 then return end
  local decoded, info = pcall(vim.json.decode, result.stdout or "")
  if decoded and type(info) == "table" then return info end
end

local function conda_interpreter(info, name)
  if not info then return end
  if name == "base" and type(info.root_prefix) == "string" then return interpreter(info.root_prefix) end
  if type(info.envs) ~= "table" then return end
  for _, prefix in ipairs(info.envs) do
    if type(prefix) == "string" and vim.fs.basename(prefix) == name then
      local executable = interpreter(prefix)
      if executable then return executable end
    end
  end
end

local function declared_conda_name(directory)
  for _, filename in ipairs({ "environment.yml", "environment.yaml" }) do
    local ok, lines = pcall(vim.fn.readfile, directory .. "/" .. filename, "", 128)
    if ok then
      for _, line in ipairs(lines) do
        local value = line:match("^name:%s*(.*)$")
        if value then
          value = vim.trim(value:gsub("%s+#.*$", ""))
          local name = value:match('^"([%w_.%-]+)"$') or value:match("^'([%w_.%-]+)'$")
            or value:match("^([%w_.%-]+)$")
          if name then return name end
        end
      end
    end
  end
end

function M.find(root)
  local active = interpreter(vim.env.VIRTUAL_ENV)
  if active then return active end
  local conda = interpreter(vim.env.CONDA_PREFIX)
  -- A non-base activation is an explicit override. Base may be auto-activated.
  if conda and vim.env.CONDA_DEFAULT_ENV ~= "base" then return conda end

  local directory = root or vim.fn.getcwd()
  local info
  while directory do
    local local_python = interpreter(directory .. "/.venv") or interpreter(directory .. "/venv")
    if local_python then return local_python end
    local name = declared_conda_name(directory)
    if name then
      if info == nil then info = conda_info() or false end
      local declared = conda_interpreter(info, name)
      if declared then return declared end
    end
    if vim.uv.fs_stat(directory .. "/.git") then break end
    local parent = vim.fs.dirname(directory)
    if parent == directory then break end
    directory = parent
  end
  if conda then return conda end
  local executable = vim.fn.exepath("python3")
  if executable == "" then executable = vim.fn.exepath("python") end
  if executable ~= "" then return executable end
end

return M
