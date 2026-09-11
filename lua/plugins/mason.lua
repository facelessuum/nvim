-- Manage formatter and language-server executables with :Mason.
-- Install on a fresh machine:
-- :MasonInstall prettier stylua ruff shfmt google-java-format php-cs-fixer rubyfmt sql-formatter taplo
-- Language servers: :MasonInstall typescript-language-server pyright ty json-lsp
-- Web/config: :MasonInstall lua-language-server html-lsp css-lsp yaml-language-server bash-language-server shellcheck marksman taplo
-- Optional: :MasonInstall gopls rust-analyzer clangd intelephense ruby-lsp
-- Install clang-format with: uv tool install clang-format
-- Go and Rust formatting use gofmt and rustfmt from their language toolchains.
require("mason").setup({})
