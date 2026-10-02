-- Resolve modules from this checkout even when loaded via -u or a different
-- default config directory (for example, a Snap installation).
local source = debug.getinfo(1, "S").source:sub(2)
local config_dir = vim.fn.fnamemodify(source, ":p:h")
vim.opt.runtimepath:prepend(config_dir)
-- Other modules use this instead of assuming ~/.config/nvim.
vim.g.config_dir = config_dir

-- LSP configuration below uses the Neovim 0.11 API. Fail clearly on older
-- distro-provided versions instead of throwing errors from every plugin.
if vim.fn.has("nvim-0.11.4") == 0 then
  vim.api.nvim_echo({ { "This config needs Neovim 0.11.4 or newer. Run setup.sh to install it.", "ErrorMsg" } }, true, {})
  return
end

-- Load core settings
require("core.options")
require("core.keymaps")
require("core.terminal").setup()
require("core.cmd")
require("core.diagnostics")

-- Load plugins
require("plugins")
