require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    markdown = { "prettier" },
    yaml = { "prettier" },
    vue = { "prettier" },
    less = { "prettier" },
    graphql = { "prettier" },
    ["markdown.mdx"] = { "prettier" },
    go = { "gofmt" },
    rust = { "rustfmt" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    cs = { "clang-format" },
    java = { "google-java-format" },
    php = { "php_cs_fixer" },
    ruby = { "rubyfmt" },
    sql = { "sql_formatter" },
    toml = { "taplo" },
    python = { "ruff_format" },
    sh = { "shfmt" },
    bash = { "shfmt" },
  },
  formatters = {
    rubyfmt = {
      cwd = function(_, ctx)
        return ctx.dirname
      end,
    },
    php_cs_fixer = {
      args = function(_, ctx)
        local config = vim.fs.find({ ".php-cs-fixer.php", ".php-cs-fixer.dist.php" }, {
          path = ctx.dirname,
          upward = true,
          type = "file",
        })[1] or (vim.fn.stdpath("config") .. "/lua/plugins/php-cs-fixer.php")
        return { "fix", "--config=" .. config, "--using-cache=no", "$FILENAME" }
      end,
    },
  },
  notify_on_error = true,
  notify_no_formatters = true,
})

vim.keymap.set({ "n", "i", "x" }, "<A-f>", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format file or selection" })
