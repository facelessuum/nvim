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

-- Install the language servers you use through :Mason.
vim.lsp.enable({
  "lua_ls", "pyright", "ts_ls", "jsonls", "html", "cssls", "yamlls",
  "taplo", "bashls", "marksman", "gopls", "rust_analyzer", "clangd",
  "intelephense", "ruby_lsp",
})
