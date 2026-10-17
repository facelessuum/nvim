-- Run from the config directory:
-- nvim --headless -u NONE -l tests/lsp_watchfiles.lua
package.path = "./lua/?.lua;" .. package.path
if vim.fn.has("nvim-0.12") == 1 then
  print("LSP watcher compatibility: not needed on Neovim 0.12+")
  return
end

local watch = vim._watch
local watchfiles = vim.lsp._watchfiles
local original = { backend = watchfiles._watchfunc, watchdirs = watch.watchdirs }
local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/nested", "p")
vim.fn.writefile({ "existing" }, root .. "/existing.py")
vim.fn.writefile({ "existing" }, root .. "/nested/existing.py")

local ok, err = xpcall(function()
  local compatibility = require("core.lsp_watchfiles")
  local native = function() end
  watchfiles._watchfunc = native
  compatibility.setup()
  assert(watchfiles._watchfunc == native, "leave other watcher backends alone")

  local emit, received_options
  local cancellations = 0
  watch.watchdirs = function(path, opts, callback)
    assert(path == root, "preserve watcher root")
    emit, received_options = callback, opts
    return function() cancellations = cancellations + 1 end
  end
  watchfiles._watchfunc = watch.watchdirs
  compatibility.setup()
  local wrapped = watchfiles._watchfunc
  assert(wrapped ~= watch.watchdirs, "wrap the affected fallback")
  compatibility.setup()
  assert(watchfiles._watchfunc == wrapped, "setup is idempotent")

  local events = {}
  local opts = { debounce = 10 }
  local cancel = wrapped(root, opts, function(path, kind)
    events[#events + 1] = { path = path, kind = kind }
  end)
  assert(received_options == opts, "preserve backend options")
  local function check(path, raw_kind, expected_kind)
    emit(root .. path, raw_kind)
    assert(events[#events].path == root .. path, "preserve event path")
    assert(events[#events].kind == expected_kind, "incorrect event kind for " .. path)
  end

  local types = watch.FileChangeType
  check("/existing.py", types.Changed, types.Changed)
  check("/nested/existing.py", types.Changed, types.Changed)
  check("/new.py", types.Changed, types.Created)
  check("/new.py", types.Changed, types.Changed)
  check("/new.py", types.Deleted, types.Deleted)
  check("/new.py", types.Changed, types.Created)
  check("/existing.py", types.Created, types.Created)

  local count = #events
  cancel()
  assert(cancellations == 1, "cancel the underlying watcher")
  emit(root .. "/late.py", types.Changed)
  assert(#events == count, "ignore pending callbacks after cancellation")
end, debug.traceback)

watch.watchdirs = original.watchdirs
watchfiles._watchfunc = original.backend
vim.fn.delete(root, "rf")
if not ok then error(err) end
print("LSP watcher compatibility: passed")
