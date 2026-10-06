require("blink.cmp").setup({
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
})
