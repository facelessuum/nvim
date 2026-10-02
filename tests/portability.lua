-- Offline unit checks: nvim --headless -u NONE -l tests/portability.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
vim.g.config_dir = root

local original = {
  executable = vim.fn.executable,
  has = vim.fn.has,
  system = vim.fn.system,
  uis = vim.api.nvim_list_uis,
  autocmd = vim.api.nvim_create_autocmd,
  notify = vim.notify,
  client = vim.lsp.get_client_by_id,
  attached = vim.lsp.buf_is_attached,
  publish = vim.lsp.diagnostic.on_publish_diagnostics,
}
local variables = { "CC", "DISPLAY", "WAYLAND_DISPLAY", "SSH_TTY", "SSH_CONNECTION", "VIRTUAL_ENV", "CONDA_PREFIX" }
local environment = {}
for _, name in ipairs(variables) do environment[name] = vim.env[name] end
local executables, features = {}, {}
vim.fn.executable = function(name) return executables[name] and 1 or 0 end
vim.fn.has = function(name)
  if name == "mac" or name == "win32" then return features[name] and 1 or 0 end
  return original.has(name)
end
local function machine(tools, flags, env)
  executables, features = tools or {}, flags or {}
  for _, name in ipairs(variables) do vim.env[name] = (env or {})[name] end
end
local function equal(actual, expected)
  assert(vim.deep_equal(actual, expected), "Expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local count = 0
local function test(name, fn)
  fn()
  count = count + 1
  print("ok " .. count .. " - " .. name)
end
local platform = require("core.platform")
local temporary = vim.fn.tempname()

local ok, err = xpcall(function()
  test("compiler detection works with CC unset", function()
    machine({ gcc = true })
    equal(platform.compilers(), { "gcc" })
    machine()
    equal(platform.compilers(), {})
  end)
  test("explicit CC takes priority", function()
    machine({ ["my-cc"] = true, cc = true }, {}, { CC = "my-cc" })
    equal(platform.compilers(), { "my-cc", "cc" })
  end)
  test("Wayland clipboard needs both copy and paste tools", function()
    machine({ ["wl-copy"] = true }, {}, { WAYLAND_DISPLAY = "wayland-0" })
    equal(platform.clipboard(), "osc52")
    executables["wl-paste"] = true
    equal(platform.clipboard(), "desktop")
  end)
  test("an X11 tool without DISPLAY is not a desktop clipboard", function()
    machine({ xclip = true }, {}, { WAYLAND_DISPLAY = "wayland-0" })
    equal(platform.clipboard(), "osc52")
    vim.env.DISPLAY = ":0"
    equal(platform.clipboard(), "desktop")
  end)
  test("SSH_CONNECTION forces terminal clipboard without SSH_TTY", function()
    machine({ xclip = true }, {}, { DISPLAY = ":0", SSH_CONNECTION = "remote local" })
    equal(platform.clipboard(), "osc52")
  end)
  test("macOS and Windows keep native clipboard support", function()
    machine({ pbcopy = true, pbpaste = true }, { mac = true })
    equal(platform.clipboard(), "desktop")
    machine({}, { win32 = true })
    equal(platform.clipboard(), "desktop")
  end)
  test("OSC 52 paste returns the last Neovim copy without querying terminal", function()
    machine()
    local sent
    package.loaded["vim.ui.clipboard.osc52"] = {
      copy = function() return function(lines) sent = lines end end,
    }
    require("core.options")
    vim.g.clipboard.copy["+"]({ "portable" }, "V")
    equal(sent, { "portable" })
    equal(vim.g.clipboard.paste["+"](), { { "portable" }, "V" })
  end)
  test("Mason Python detection accepts python and rejects Python 2", function()
    machine({ python = true }, { win32 = true })
    vim.fn.system = function(command) return command[1] == "python" and "3\n" or "2\n" end
    equal(platform.python(), "python")
    machine({ python3 = true, python = true })
    equal(platform.python(), "python")
    machine({ python3 = true })
    equal(platform.python(), nil)
    vim.fn.system = original.system
  end)
  test("Python environment prefers nearest project over active global environment", function()
    local project = temporary .. "/repo"
    vim.fn.mkdir(project .. "/member", "p")
    vim.fn.mkdir(project .. "/.git", "p")
    machine({ [project .. "/.venv/bin/python"] = true, ["/active/bin/python"] = true }, {}, { VIRTUAL_ENV = "/active" })
    equal(require("core.python_environment").find(project .. "/member"), project .. "/.venv/bin/python")
  end)
  test("Python environment also supports Windows venv and Conda layouts", function()
    local project = temporary .. "/repo"
    machine({ [project .. "/.venv/Scripts/python.exe"] = true })
    equal(require("core.python_environment").find(project), project .. "/.venv/Scripts/python.exe")
    machine({ [temporary .. "/conda/python.exe"] = true }, {}, { CONDA_PREFIX = temporary .. "/conda" })
    equal(require("core.python_environment").find(project), temporary .. "/conda/python.exe")
  end)
  test("Treesitter uses the detected compiler but does not download in headless mode", function()
    machine({ gcc = true })
    local config
    package.loaded["nvim-treesitter.install"] = {}
    package.loaded["nvim-treesitter.configs"] = { setup = function(value) config = value end }
    vim.api.nvim_list_uis = function() return {} end
    dofile(root .. "/lua/plugins/treesitter.lua")
    equal(package.loaded["nvim-treesitter.install"].compilers, { "gcc" })
    equal(config.ensure_installed, {})
    equal(config.auto_install, false)
    vim.api.nvim_list_uis = function() return { {} } end
    dofile(root .. "/lua/plugins/treesitter.lua")
    assert(#config.ensure_installed > 0)
    equal(config.auto_install, true)
    machine()
    dofile(root .. "/lua/plugins/treesitter.lua")
    equal(config.ensure_installed, {})
    equal(config.auto_install, false)
  end)
  test("Mason skips headless installs and warns on offline refresh", function()
    local enter, refreshes, warnings = nil, 0, {}
    vim.api.nvim_create_autocmd = function(_, options) enter = options.callback end
    vim.notify = function(message) table.insert(warnings, message) end
    package.loaded["mason"] = { setup = function() end }
    package.loaded["mason-registry"] = {
      refresh = function(callback) refreshes = refreshes + 1; callback(false) end,
      get_package = function() return { is_installed = function() return true end } end,
    }
    dofile(root .. "/lua/plugins/mason.lua")
    vim.api.nvim_create_autocmd = original.autocmd
    vim.api.nvim_list_uis = function() return {} end
    enter()
    equal(refreshes, 0)
    vim.api.nvim_list_uis = function() return { {} } end
    enter()
    assert(vim.wait(1000, function() return #warnings > 0 end))
    equal(refreshes, 1)
    assert(warnings[1]:match("refresh failed"))
    vim.notify = original.notify
  end)
  test("Python diagnostics accept reports when the buffer version is unknown", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local path = temporary .. "/diagnostics.py"
    vim.api.nvim_buf_set_name(buf, path)
    local published = 0
    vim.lsp.get_client_by_id = function() return { is_stopped = function() return false end } end
    vim.lsp.buf_is_attached = function() return true end
    vim.lsp.diagnostic.on_publish_diagnostics = function() published = published + 1 end
    local result, ctx = { uri = vim.uri_from_fname(path), version = 5 }, { client_id = 1 }
    vim.lsp.util.buf_versions[buf] = nil
    require("core.python_diagnostics").publish(nil, result, ctx)
    equal(published, 1)
    vim.lsp.util.buf_versions[buf] = 6
    require("core.python_diagnostics").publish(nil, result, ctx)
    equal(published, 1)
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.lsp.get_client_by_id, vim.lsp.buf_is_attached = original.client, original.attached
    vim.lsp.diagnostic.on_publish_diagnostics = original.publish
  end)
  test("Telescope does not require sh to search files", function()
    local config
    package.loaded["telescope"] = {
      setup = function(value) config = value end,
      load_extension = function() end,
    }
    package.loaded["telescope.actions"] = { close = function() end, select_vertical = function() end }
    machine({ rg = true })
    dofile(root .. "/lua/plugins/telescope.lua")
    equal(config.pickers.find_files.find_command[1], "rg")
    machine({ rg = true, sh = true })
    dofile(root .. "/lua/plugins/telescope.lua")
    equal(config.pickers.find_files.find_command[1], "rg")
    executables.sort = true
    dofile(root .. "/lua/plugins/telescope.lua")
    equal(config.pickers.find_files.find_command[1], "sh")
    machine()
    dofile(root .. "/lua/plugins/telescope.lua")
    equal(config.pickers.find_files.find_command, nil)
  end)
  test("Blink allows a Lua fallback without Rust or prebuilt binaries", function()
    local config
    package.loaded["blink.cmp"] = { setup = function(value) config = value end }
    dofile(root .. "/lua/plugins/blinkcmp.lua")
    equal(config.fuzzy.implementation, "prefer_rust")
  end)
end, debug.traceback)

vim.fn.executable, vim.fn.has, vim.fn.system = original.executable, original.has, original.system
vim.api.nvim_list_uis, vim.api.nvim_create_autocmd, vim.notify = original.uis, original.autocmd, original.notify
vim.lsp.get_client_by_id, vim.lsp.buf_is_attached = original.client, original.attached
vim.lsp.diagnostic.on_publish_diagnostics = original.publish
for _, name in ipairs(variables) do vim.env[name] = environment[name] end
vim.fn.delete(temporary, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
print("Passed " .. count .. " portability checks")
