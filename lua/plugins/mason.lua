-- Manage formatter and language-server executables with :Mason.
-- Missing tools below install automatically on first launch of a new machine.
-- Optional (install manually if you use them):
-- :MasonInstall gopls rust-analyzer clangd intelephense ruby-lsp google-java-format php-cs-fixer rubyfmt
-- Install clang-format with: uv tool install clang-format
-- Go and Rust formatting use gofmt and rustfmt from their language toolchains.
require("mason").setup({})

local tools = {
  -- Language servers
  "typescript-language-server", "pyright", "ty", "json-lsp", "lua-language-server",
  "html-lsp", "css-lsp", "yaml-language-server", "bash-language-server", "marksman", "taplo",
  -- Formatters and linters
  "prettier", "stylua", "ruff", "shfmt", "shellcheck", "sql-formatter",
}

-- Mason needs these runtimes to build packages from each ecosystem.
local runtimes = {
  npm = { "npm" },
  pypi = { "python3" },
  cargo = { "cargo" },
  golang = { "go" },
  composer = { "composer", "php" },
  gem = { "gem" },
}

-- Python packages need venv support (python3-venv on Debian/Ubuntu).
local function python_venv_ok()
  if vim.fn.executable("python3") == 0 then return false end
  vim.fn.system({ "python3", "-c", "import venv, ensurepip" })
  return vim.v.shell_error == 0
end

local function install_missing()
  local registry = require("mason-registry")
  local skipped = {}
  for _, name in ipairs(tools) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and not pkg:is_installed() and not pkg:is_installing() then
      local ecosystem = pkg.spec.source.id:match("^pkg:(%w+)/")
      local missing
      for _, executable in ipairs(runtimes[ecosystem] or {}) do
        if vim.fn.executable(executable) == 0 then missing = executable end
      end
      if ecosystem == "pypi" and not missing and not python_venv_ok() then
        missing = "python3-venv"
      end
      if missing then
        skipped[missing] = skipped[missing] or {}
        table.insert(skipped[missing], name)
      else
        pkg:install()
      end
    end
  end
  for runtime, names in pairs(skipped) do
    vim.notify(("Mason: install %s to get %s, then restart Neovim."):format(runtime, table.concat(names, ", ")),
      vim.log.levels.WARN)
  end
end

-- Wait for the UI so installation never delays startup or headless runs.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if #vim.api.nvim_list_uis() == 0 then return end
    require("mason-registry").refresh(vim.schedule_wrap(install_missing))
  end,
})
