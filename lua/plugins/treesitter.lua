-- Parsers are compiled locally: needs git or curl+tar, and a C compiler (cc/gcc/clang).
local has_compiler = vim.iter({ vim.env.CC, "cc", "gcc", "clang", "zig" }):any(function(cc)
  return cc and cc ~= "" and vim.fn.executable(cc) == 1
end)

require("nvim-treesitter.configs").setup({
  ensure_installed = not has_compiler and {} or { "lua", "vim", "vimdoc", "query", "javascript", "typescript", "python", "bash", "json", "html", "css" },
  -- Skip compiling on machines without a compiler instead of erroring on every file.
  auto_install = has_compiler,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
})
