local M = {}

-- Neovim 0.11 accepts push diagnostics without checking their document version.
-- Keep delayed reports from replacing diagnostics for newer Python edits.
function M.publish(err, result, ctx, config)
  if err or not result then return end
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local bufnr = vim.fn.bufnr(vim.uri_to_fname(result.uri))
  if not client or client:is_stopped() or bufnr == -1
    or not vim.lsp.buf_is_attached(bufnr, ctx.client_id) then return end
  local version = vim.lsp.util.buf_versions[bufnr]
  if type(result.version) == "number" and type(version) == "number" and result.version < version then
    return
  end
  -- Empty current reports must reach the normal handler to clear all displays.
  return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
end

return M
