-- Keep platform/dependency detection shared by plugins and :checkhealth config.
local M = {}

function M.compilers()
  local candidates = { "cc", "gcc", "clang", "zig", "cl" }
  if vim.env.CC and vim.env.CC ~= "" then table.insert(candidates, 1, vim.env.CC) end
  local available = {}
  for _, compiler in ipairs(candidates) do
    if vim.fn.executable(compiler) == 1 then table.insert(available, compiler) end
  end
  return available
end

function M.python()
  local candidates = vim.fn.has("win32") == 1 and { "python", "python3" } or { "python3", "python" }
  for _, executable in ipairs(candidates) do
    if vim.fn.executable(executable) == 1 then
      local major = vim.fn.system({ executable, "-c", "import sys; print(sys.version_info[0])" })
      if vim.v.shell_error == 0 and vim.trim(major) == "3" then return executable end
    end
  end
end

function M.clipboard()
  -- A locally installed clipboard tool cannot access the SSH client's desktop.
  if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then return "osc52" end
  if vim.fn.has("mac") == 1 and vim.fn.executable("pbcopy") == 1
    and vim.fn.executable("pbpaste") == 1 then return "desktop" end
  if vim.fn.has("win32") == 1 then return "desktop" end
  if vim.env.WAYLAND_DISPLAY and vim.env.WAYLAND_DISPLAY ~= ""
    and vim.fn.executable("wl-copy") == 1 and vim.fn.executable("wl-paste") == 1 then
    return "desktop"
  end
  if vim.env.DISPLAY and vim.env.DISPLAY ~= ""
    and (vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1) then
    return "desktop"
  end
  return "osc52"
end

return M
