vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
    },
  },
})

-- uv sync installs into .venv without activating it in Neovim's shell.
-- Select the project's interpreter before Pyright starts resolving imports.
vim.lsp.config("pyright", {
  before_init = function(_, config)
    local python = config.settings.python
    if python.pythonPath then return end
    python.pythonPath = require("core.python_environment").find(config.root_dir)
  end,
})

-- Install the language servers you use through :Mason.
vim.lsp.enable({
  "lua_ls", "pyright", "ts_ls", "jsonls", "html", "cssls", "yamlls",
  "taplo", "bashls", "marksman", "gopls", "rust_analyzer", "clangd",
  "intelephense", "ruby_lsp",
})
