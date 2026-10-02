require("blink.cmp").setup({
  -- Completion must also work on architectures without a prebuilt Rust matcher.
  fuzzy = { implementation = "prefer_rust" },
  keymap = {
    preset = "default",
    ["<S-Tab>"] = { "fallback" },
    ["<C-y>"] = { "fallback" },
    ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
  },
  completion = {
    list = {
      selection = {
        preselect = true,
        auto_insert = false,
      },
    },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      lsp = {
        transform_items = function(ctx, items)
          if vim.bo[ctx.bufnr].filetype ~= "python" then return items end
          local ty = vim.lsp.get_clients({ bufnr = ctx.bufnr, name = "ty" })[1]
          if not ty or not ty.initialized then return items end
          return vim.tbl_filter(function(item)
            local client = vim.lsp.get_client_by_id(item.client_id)
            return not client or client.name ~= "pyright"
          end, items)
        end,
      },
    },
  },
})
