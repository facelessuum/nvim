-- Run with: nvim --headless -u NONE -l scripts/setup_treesitter.lua
-- Repair only the plugin checkout, without loading the user's configuration.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local data = vim.fn.stdpath("data")
local plugin = data .. "/lazy/nvim-treesitter"
local staging

local function git(args)
  local command = { "git" }
  vim.list_extend(command, args)
  -- Dotfile/bare-repository shell setups can export these variables. They must
  -- not redirect this clone/checkout into another repository or working tree.
  local variables = { "GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR", "GIT_INDEX_FILE", "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES" }
  local saved = {}
  for _, name in ipairs(variables) do
    saved[name] = vim.env[name]
    vim.env[name] = nil
  end
  local ran, output = pcall(vim.fn.system, command)
  local status = vim.v.shell_error
  for _, name in ipairs(variables) do vim.env[name] = saved[name] end
  if not ran then return false, tostring(output) end
  return status == 0, vim.trim(output)
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
  print("Installing Treesitter lockfile revision " .. pinned.commit .. "...")
  checked_git({ "clone", "--filter=blob:none", "--no-checkout", "--branch", pinned.branch,
    "https://github.com/nvim-treesitter/nvim-treesitter.git", staging })
  local module = "lua/nvim-treesitter/configs.lua"
  local has_blob, blob_err = git({ "-C", staging, "cat-file", "-e", pinned.commit .. ":" .. module })
  if not has_blob then
    error("Treesitter lockfile revision " .. pinned.commit .. " could not be verified as a legacy revision:\n"
      .. blob_err .. "\nBack up lazy-lock.json, then restore the repository's tested lockfile with "
      .. "git restore --source=HEAD -- lazy-lock.json and rerun setup.", 0)
  end
  -- Materialize the full tree even if global/template config enables sparse
  -- checkout or redirects core.worktree. Do not alter the user's Git settings.
  checked_git({ "-C", staging, "--work-tree=" .. staging, "-c", "core.sparseCheckout=false",
    "checkout", "--detach", pinned.commit })
  assert(vim.fn.filereadable(staging .. "/" .. module) == 1,
    "Treesitter revision " .. pinned.commit .. " contains " .. module
      .. " but Git did not materialize it at " .. staging .. ". Check Git checkout settings and permissions.")

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
  io.stderr:write("Treesitter setup failed: " .. tostring(err) .. "\nNo existing plugin was discarded. Resolve the error above and rerun bash setup.sh.\n")
  vim.cmd("cquit 1")
end
