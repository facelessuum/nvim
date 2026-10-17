local M = {}

function M.setup()
  local watch = vim._watch
  local watchfiles = vim.lsp._watchfiles
  -- Only patch the affected 0.11 fallback. Prefer Neovim's native/inotify
  -- backends when available, and leave newer Neovim implementations alone.
  if vim.fn.has("nvim-0.12") == 1 or watchfiles._watchfunc ~= watch.watchdirs then return end

  watchfiles._watchfunc = function(path, opts, callback)
    opts = opts or {}
    local known = {}
    local cancelled = false
    local function excluded(name)
      return opts.exclude_pattern and opts.exclude_pattern:match(name) ~= nil
    end

    -- watchdirs merges CREATE and MODIFY into Changed when a file is created
    -- and written in one burst. Pyright needs Created to invalidate imports.
    -- Remember existing paths so the debounced event retains that distinction.
    for name in vim.fs.dir(path, {
      depth = 100,
      skip = function(name) return not excluded(vim.fs.joinpath(path, name)) end,
    }) do
      local fullpath = vim.fs.joinpath(path, name)
      if not excluded(fullpath) then known[fullpath] = true end
    end

    local cancel = watch.watchdirs(path, opts, function(fullpath, change_type)
      if cancelled then return end
      if change_type == watch.FileChangeType.Deleted then
        known[fullpath] = nil
      else
        if not known[fullpath] then change_type = watch.FileChangeType.Created end
        known[fullpath] = true
      end
      callback(fullpath, change_type)
    end)

    return function()
      cancelled = true
      cancel()
      known = {}
    end
  end
end

return M
