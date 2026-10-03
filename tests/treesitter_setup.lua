-- Offline regression checks for the standalone setup repair.
-- Run: nvim --headless -u NONE -l tests/treesitter_setup.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local pinned = vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))["nvim-treesitter"].commit
local temporary = vim.fn.tempname()
local original = { system = vim.fn.system, stdpath = vim.fn.stdpath, cmd = vim.cmd }
local data, plugin, revisions, commands, clone_fails, checkout_fails, exit_status
local count = 0

vim.fn.stdpath = function(name)
  assert(name == "data")
  return data
end
vim.cmd = function(command)
  assert(command == "cquit 1")
  exit_status = 1
end
vim.fn.system = function(command)
  table.insert(commands, command)
  assert(command[1] == "git")
  original.system({ "/bin/sh", "-c", "exit 0" })
  if command[2] == "clone" then
    if clone_fails then
      vim.fn.mkdir(command[#command], "p") -- Git can leave a partial checkout.
      original.system({ "/bin/sh", "-c", "exit 1" })
      return "simulated offline failure"
    end
    assert(vim.tbl_contains(command, "master"))
    local staging = command[#command]
    vim.fn.mkdir(staging .. "/lua/nvim-treesitter", "p")
    vim.fn.writefile({ "return {}" }, staging .. "/lua/nvim-treesitter/configs.lua")
    return ""
  end
  assert(command[2] == "-C")
  if command[4] == "rev-parse" then return revisions[command[3]] or "wrong-revision" end
  assert(command[4] == "checkout" and command[5] == "--detach" and command[6] == pinned)
  if checkout_fails then
    original.system({ "/bin/sh", "-c", "exit 1" })
    return "simulated checkout failure"
  end
  return ""
end

local function test(name, fn)
  count = count + 1
  data = temporary .. "/" .. count
  plugin = data .. "/lazy/nvim-treesitter"
  revisions, commands, clone_fails, checkout_fails, exit_status = {}, {}, false, false, nil
  fn()
  print("ok " .. count .. " - " .. name)
end
local function existing(with_module)
  vim.fn.mkdir(plugin, "p")
  vim.fn.writefile({ "keep this installation" }, plugin .. "/marker")
  if with_module then
    vim.fn.mkdir(plugin .. "/lua/nvim-treesitter", "p")
    vim.fn.writefile({ "return {}" }, plugin .. "/lua/nvim-treesitter/configs.lua")
  end
end
local function repair()
  dofile(root .. "/scripts/setup_treesitter.lua")
end
local function repaired_with_backup()
  assert(not exit_status)
  assert(vim.fn.filereadable(plugin .. "/lua/nvim-treesitter/configs.lua") == 1)
  assert(vim.fn.filereadable(plugin .. "/marker") == 0)
  local backups = vim.fn.glob(data .. "/treesitter-backups/*", false, true)
  assert(#backups == 1)
  assert(vim.fn.readfile(backups[1] .. "/marker")[1] == "keep this installation")
end

local ok, err = xpcall(function()
  test("matching pinned installation needs no download or checkout", function()
    existing(true)
    revisions[plugin] = pinned
    repair()
    assert(not exit_status and #commands == 1)
    assert(vim.fn.filereadable(plugin .. "/marker") == 1)
  end)
  test("fresh installation uses the pinned legacy revision", function()
    repair()
    assert(not exit_status and #commands == 2)
    assert(vim.fn.filereadable(plugin .. "/lua/nvim-treesitter/configs.lua") == 1)
  end)
  test("new API installation is replaced and preserved outside Lazy", function()
    existing(false)
    repair()
    repaired_with_backup()
  end)
  test("wrong revision with legacy module is restored to lockfile", function()
    existing(true)
    repair()
    repaired_with_backup()
  end)
  test("missing module is repaired even when HEAD matches the lockfile", function()
    existing(false)
    revisions[plugin] = pinned
    repair()
    repaired_with_backup()
  end)
  test("failed download leaves the old installation untouched", function()
    existing(false)
    clone_fails = true
    repair()
    assert(exit_status == 1)
    assert(vim.fn.filereadable(plugin .. "/marker") == 1)
    assert(#vim.fn.glob(plugin .. ".setup-*", false, true) == 0)
    assert(#vim.fn.glob(data .. "/treesitter-backups/*", false, true) == 0)
  end)
  test("failed pinned checkout also preserves the original plugin", function()
    existing(true)
    checkout_fails = true
    repair()
    assert(exit_status == 1)
    assert(vim.fn.filereadable(plugin .. "/marker") == 1)
    assert(#vim.fn.glob(plugin .. ".setup-*", false, true) == 0)
    assert(#vim.fn.glob(data .. "/treesitter-backups/*", false, true) == 0)
  end)
end, debug.traceback)
vim.fn.system, vim.fn.stdpath, vim.cmd = original.system, original.stdpath, original.cmd
vim.fn.delete(temporary, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
print("Passed " .. count .. " Treesitter setup checks.")
