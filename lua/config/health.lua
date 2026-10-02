-- Run with :checkhealth config. No installation or network access is performed.
local M = {}

function M.check()
  local health = vim.health
  local platform = require("core.platform")
  health.start("Portable Neovim configuration")
  if vim.fn.has("nvim-0.11.4") == 1 then
    health.ok("Neovim " .. tostring(vim.version()))
    if vim.fn.has("nvim-0.12") == 1 then
      health.warn("Neovim 0.12+ is not tested with this config's legacy Treesitter branch; use 0.11.x if parsers fail.")
    end
  else
    health.error("Neovim 0.11.4+ is required", { "Run bash setup.sh or install a current Neovim." })
  end
  health.info("Checkout: " .. (vim.g.config_dir or "not loaded"))
  health.info("Plugin data: " .. vim.fn.stdpath("data"))

  local tools = {
    { "git", "Required to install plugins." },
    { "curl", "Used to download plugins, parsers, and Mason packages." },
    { "tar", "Required to extract downloaded archives." },
    { "unzip", "Required by some Mason packages." },
    { "rg", "Recommended for file search; Telescope can fall back to fd/find." },
    { "node", "Required by JavaScript-based language servers and formatters; use a current Node LTS." },
    { "npm", "Required to install JavaScript-based Mason tools." },
  }
  for _, tool in ipairs(tools) do
    local path = vim.fn.exepath(tool[1])
    if path ~= "" then
      health.ok(tool[1] .. ": " .. path)
    else
      health.warn(tool[1] .. " is missing. " .. tool[2], { "Run bash setup.sh, or install it yourself without sudo." })
    end
  end
  local python = platform.python()
  if python then
    health.ok("Python 3: " .. vim.fn.exepath(python))
    vim.fn.system({ python, "-c", "import venv, ensurepip" })
    if vim.v.shell_error ~= 0 then
      health.warn("Python venv/ensurepip is unavailable", { "On Debian/Ubuntu: install python3-venv." })
    end
  else
    health.warn("Python 3 is missing; Python-based Mason tools cannot be installed.",
      { "Install Python 3 with venv/ensurepip and put python3 (or python) on PATH." })
  end
  if vim.fn.executable("node") == 1 then
    local version = vim.fn.system({ "node", "--version" })
    local major = tonumber(version:match("v(%d+)"))
    if major and major < 20 then
      health.warn("Node.js " .. vim.trim(version) .. " is old; some Mason packages require Node 20+.",
        { "Install a current Node LTS and ensure it is on PATH before starting Neovim." })
    end
  end

  local compilers = platform.compilers()
  if #compilers > 0 then
    health.ok("Treesitter compiler: " .. compilers[1])
  else
    health.warn("No C compiler: parser installation is disabled; existing parsers still work.")
  end
  if vim.fn.executable("make") == 0 or #compilers == 0 then
    health.info("Telescope uses its Lua sorter because native build tools are missing.")
  end
  if platform.clipboard() == "osc52" then
    health.info("Clipboard: OSC 52 (terminal must support it). Paste uses the last copy made inside Neovim.")
    health.info("For desktop paste on Linux, install wl-clipboard (Wayland) or xclip/xsel (X11).")
  else
    health.ok("Desktop clipboard available")
  end
  health.info("Go/Rust/Java/PHP/Ruby tools are optional; install their runtimes and tools only if needed (see README).")
end

return M
