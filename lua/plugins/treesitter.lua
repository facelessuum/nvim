-- Keep the legacy master branch pinned, but tolerate a newer or incomplete
-- checkout on another machine without failing the entire plugin config.
local parsers = { "lua", "vim", "vimdoc", "query", "javascript", "typescript", "python", "bash", "json", "html", "css" }
local compilers = require("core.platform").compilers()
local has_compiler = #compilers > 0
-- Do not start downloads/compilation during headless checks or scripted edits.
local interactive = #vim.api.nvim_list_uis() > 0
local can_install = has_compiler and interactive
local repair = "Close Neovim and run bash setup.sh from this config checkout to restore the pinned Treesitter version."

local has_legacy, legacy = pcall(require, "nvim-treesitter.configs")
if has_legacy then
  if has_compiler then require("nvim-treesitter.install").compilers = compilers end
  legacy.setup({
    ensure_installed = can_install and parsers or {},
    auto_install = can_install,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
  })
  return
end

-- The main branch no longer exports configs/setup's legacy options, and its
-- current API requires Neovim 0.12+. Do not try to load it on 0.11.
if vim.fn.has("nvim-0.12") == 0 then
  vim.notify("Treesitter's legacy API is unavailable; the newer API needs Neovim 0.12+. " .. repair, vim.log.levels.WARN)
  return
end

local has_modern, treesitter = pcall(require, "nvim-treesitter")
if not has_modern or type(treesitter) ~= "table" or type(treesitter.setup) ~= "function" then
  vim.notify("Treesitter is missing or incomplete. " .. repair, vim.log.levels.WARN)
  return
end
local configured, err = pcall(treesitter.setup, {})
if not configured then
  vim.notify("Treesitter setup failed: " .. tostring(err) .. ". " .. repair, vim.log.levels.WARN)
  return
end

-- The rewritten plugin only manages parsers/queries. Highlighting must be
-- explicitly enabled through Neovim, and missing parsers must not throw errors.
vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("ConfigTreesitterHighlight", { clear = true }),
  callback = function(event)
    if not vim.api.nvim_buf_is_valid(event.buf) or vim.bo[event.buf].buftype ~= "" then return end
    local language = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
    if language then pcall(vim.treesitter.start, event.buf, language) end
  end,
})

-- The modern installer additionally requires the tree-sitter CLI and curl/tar.
if can_install then
  local missing = {}
  for _, tool in ipairs({ "tree-sitter", "curl", "tar" }) do
    if vim.fn.executable(tool) == 0 then missing[#missing + 1] = tool end
  end
  if #missing > 0 then
    vim.notify("Treesitter parser installation skipped; missing: " .. table.concat(missing, ", ") .. ". " .. repair, vim.log.levels.WARN)
  elseif type(treesitter.install) == "function" then
    local installed, install_err = pcall(treesitter.install, parsers)
    if not installed then
      vim.notify("Treesitter parser installation failed: " .. tostring(install_err), vim.log.levels.WARN)
    end
  end
end
