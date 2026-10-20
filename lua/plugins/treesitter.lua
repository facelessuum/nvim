-- Use Neovim's native highlighter, not the legacy nvim-treesitter.configs API.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
  callback = function(args)
    -- Parsers are installed manually; unsupported filetypes keep normal syntax.
    pcall(vim.treesitter.start, args.buf)
  end,
})
