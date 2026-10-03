-- Run with: nvim --headless -u NONE -l scripts/setup_treesitter.lua
-- Repair only the plugin checkout, without loading the user's configuration.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local data = vim.fn.stdpath("data")
local plugin = data .. "/lazy/nvim-treesitter"
local staging

local function git(args)
  local command = { "git" }
  vim.list_extend(command, args)
  local output = vim.fn.system(command)
  return vim.v.shell_error == 0, vim.trim(output)
end

local function checked_git(args)
  local ok, output = git(args)
  if not ok then error("git " .. table.concat(args, " ") .. " failed:\n" .. output, 0) end
  return output
end

local ok, err = pcall(function()
  local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))
  local pinned = assert(lock["nvim-treesitter"], "Treesitter is missing from lazy-lock.json")
  assert(type(pinned.commit) == "string" and #pinned.commit == 40 and pinned.commit:match("^%x+$"),
    "Treesitter lockfile commit must be a full Git SHA")
  assert(pinned.branch == "master", "This config requires the legacy Treesitter master branch")

  local has_module = vim.fn.filereadable(plugin .. "/lua/nvim-treesitter/configs.lua") == 1
  if has_module then
    local installed, revision = git({ "-C", plugin, "rev-parse", "HEAD" })
    if installed and revision == pinned.commit then
      print("Treesitter already matches lazy-lock.json.")
      return
    end
  end

  -- Prepare and verify the replacement before moving an existing installation.
  vim.fn.mkdir(vim.fn.fnamemodify(plugin, ":h"), "p")
  staging = plugin .. ".setup-" .. vim.fn.getpid() .. "-" .. tostring(vim.uv.hrtime())
  print("Installing the legacy Treesitter revision from lazy-lock.json...")
  checked_git({ "clone", "--filter=blob:none", "--no-checkout", "--branch", pinned.branch,
    "https://github.com/nvim-treesitter/nvim-treesitter.git", staging })
  checked_git({ "-C", staging, "checkout", "--detach", pinned.commit })
  assert(vim.fn.filereadable(staging .. "/lua/nvim-treesitter/configs.lua") == 1,
    "The pinned Treesitter revision does not provide nvim-treesitter.configs")

  local backup
  if vim.uv.fs_lstat(plugin) then
    local backups = data .. "/treesitter-backups"
    vim.fn.mkdir(backups, "p")
    backup = backups .. "/nvim-treesitter-" .. vim.fn.getpid() .. "-" .. tostring(vim.uv.hrtime())
    local moved, move_err = vim.uv.fs_rename(plugin, backup)
    assert(moved, move_err)
  end
  local moved, move_err = vim.uv.fs_rename(staging, plugin)
  if not moved then
    if backup then
      local restored, restore_err = vim.uv.fs_rename(backup, plugin)
      if not restored then
        error("Install failed: " .. tostring(move_err) .. "; restore failed: " .. tostring(restore_err)
          .. ". Previous plugin is preserved at " .. backup, 0)
      end
    end
    error(move_err, 0)
  end
  staging = nil
  if backup then print("Previous Treesitter installation saved to " .. backup) end
  print("Treesitter repaired. Restart Neovim; run :TSUpdate to refresh existing parsers.")
end)

if staging then vim.fn.delete(staging, "rf") end
if not ok then
  io.stderr:write("Treesitter setup failed: " .. tostring(err) .. "\nCheck Git/network access and rerun bash setup.sh.\n")
  vim.cmd("cquit 1")
end
