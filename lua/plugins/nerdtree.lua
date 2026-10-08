require("nvim-tree").setup ({
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")
    api.config.mappings.default_on_attach(bufnr)

    vim.keymap.set("n", "<C-e>", "<cmd>Telescope find_files<CR>", {
      buffer = bufnr,
      silent = true,
      desc = "Find files with Telescope",
    })

    local function create_file_or_folder()
      local node = api.tree.get_node_under_cursor()
      if not node then return end
      local directory = node.absolute_path
      if vim.fn.isdirectory(directory) == 0 then
        directory = vim.fn.fnamemodify(directory, ":h")
      end
      vim.ui.input({ prompt = "Create file or folder: ", default = directory .. "/", completion = "file" }, function(path)
        if not path or path == "" or path == directory .. "/" then return end
        local name = vim.fn.fnamemodify(path:gsub("/+$", ""), ":t")
        local is_folder = path:sub(-1) == "/" or not name:match("%..+$")
        if vim.uv.fs_lstat(path) then
          vim.notify("Already exists: " .. path, vim.log.levels.WARN)
          return
        end
        local ok, err = pcall(function()
          if is_folder then
            vim.fn.mkdir(path, "p")
          else
            vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
            local fd, message = vim.uv.fs_open(path, "wx", 420)
            if not fd then error(message) end
            vim.uv.fs_close(fd)
          end
        end)
        if not ok then
          vim.notify("Could not create: " .. tostring(err), vim.log.levels.ERROR)
          return
        end
        api.tree.reload()
        api.tree.find_file({ buf = path, open = true, focus = true })
      end)
    end

    vim.keymap.set("n", "n", create_file_or_folder, {
      buffer = bufnr,
      silent = true,
      desc = "Create file with extension or folder without extension",
    })

    local function open_and_keep_focus()
      api.node.open.no_window_picker()
      api.tree.focus()
    end
    for _, key in ipairs({ "<CR>", "s", "<2-LeftMouse>" }) do
      vim.keymap.set("n", key, open_and_keep_focus, {
        buffer = bufnr,
        silent = true,
        desc = "Open file or toggle folder; stay in tree",
      })
    end

    vim.keymap.set("n", "<C-s>", function()
      -- Put the new file to the right of the editor, before the right-side tree.
      local splitright = vim.o.splitright
      vim.o.splitright = true
      local ok, err = pcall(api.node.open.vertical_no_picker, nil, { focus = true })
      vim.o.splitright = splitright
      if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
    end, {
      buffer = bufnr,
      silent = true,
      desc = "Open file in right vertical split; stay in tree",
    })

    vim.keymap.set("n", "o", function()
      local node = api.tree.get_node_under_cursor()
      if not node or not node.absolute_path then return end
      local directory = node.absolute_path
      if vim.fn.isdirectory(directory) == 0 then
        directory = vim.fn.fnamemodify(directory, ":h")
      end
      local _, err = vim.ui.open(directory)
      if err then vim.notify(tostring(err), vim.log.levels.ERROR) end
    end, {
      buffer = bufnr,
      silent = true,
      desc = "Open folder in system file manager",
    })

    vim.keymap.set("n", "i", function()
      local windows = { vim.fn.win_getid(vim.fn.winnr("#")) }
      vim.list_extend(windows, vim.api.nvim_tabpage_list_wins(0))
      for _, win in ipairs(windows) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          local opts = vim.bo[buf]
          if opts.buftype == "" and opts.modifiable and vim.api.nvim_win_get_config(win).relative == "" then
            vim.api.nvim_set_current_win(win)
            vim.cmd.startinsert()
            return
          end
        end
      end
      vim.notify("No editing window available in this tab", vim.log.levels.INFO)
    end, { buffer = bufnr, silent = true, desc = "Return to file and insert" })
  end,
  view = {
    width = 40,
    side = "right",
  },
  tab = {
    sync = {
      open = true,
      close = true,
    },
  },
  diagnostics = {
    enable = true,
    show_on_dirs = true,
    show_on_open_dirs = true,
    severity = {
      min = vim.diagnostic.severity.WARN,
      max = vim.diagnostic.severity.ERROR,
    },
    icons = {
      error = "E",
      warning = "W",
      info = "I",
      hint = "H",
    },
  },
  renderer = {
    highlight_diagnostics = "name",
    icons = {
      diagnostics_placement = "after",
      web_devicons = {
        file = { enable = true, color = true },
      },
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
      },
      glyphs = {
        folder = {
          default = "",
          open = "",
          empty = "",
          empty_open = "",
        },
      },
    },
  },
  filters = {
    enable = true,
    dotfiles = false,
    git_ignored = false,
    custom = function(path)
      local name = vim.fn.fnamemodify(path, ":t")
      return (name:sub(1, 1) == "." or name == "__pycache__") and vim.fn.isdirectory(path) == 1
    end,
  }
})

vim.keymap.set({ "n", "i" }, "<C-f>", "<Esc><cmd>NvimTreeFindFileToggle!<CR>", {
  desc = "Toggle file tree and reveal current file",
})
