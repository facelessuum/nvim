local function select_prompt_text(prompt_bufnr)
  local prefix = vim.fn.prompt_getprompt(prompt_bufnr)
  local line = vim.api.nvim_buf_get_lines(prompt_bufnr, 0, 1, false)[1] or ""
  if #line <= #prefix then return end
  local prefix_length = vim.fn.strchars(prefix)
  local start = prefix_length > 0 and (prefix_length .. "l") or ""
  local finish = vim.o.selection == "exclusive" and "$" or "$h"
  local keys = "<Esc>0" .. start .. "v" .. finish .. "<C-g>"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

local function open_file(command)
  return function(prompt_bufnr)
    require("telescope.actions.set").edit(prompt_bufnr, command)
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    -- Telescope queues mode changes while closing its prompt. Resume typing afterward.
    vim.defer_fn(function()
      if vim.api.nvim_get_current_win() == win and vim.api.nvim_get_current_buf() == buf
        and vim.bo[buf].buftype == "" and vim.bo[buf].modifiable then
        vim.cmd("startinsert")
      end
    end, 10)
  end
end

require("telescope").setup({
  pickers = {
    find_files = {
      -- Honor .gitignore even in folders without a Git repository.
      hidden = true,
      -- Merge normal results with explicit environment-file exceptions.
      find_command = {
        "sh", "-c", [[
          {
            rg --files --hidden --color never --no-require-git --glob '!.git'
            rg --files --hidden --color never --no-require-git --glob '.env' --glob '.env.*' --glob '.envrc' --glob '!.git'
          } | sort -u
        ]],
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
  defaults = {
    -- Bound preview work when scrolling across large/minified files.
    preview = {
      filesize_limit = 0.5,
      highlight_limit = 0.1,
      treesitter = false,
    },
    mappings = {
      i = {
        ["<C-w>"] = require("telescope.actions").close,
        ["<C-a>"] = select_prompt_text,
        ["<A-w>"] = open_file("leftabove new"),
        ["<A-a>"] = open_file("leftabove vnew"),
        ["<A-s>"] = open_file("rightbelow new"),
        ["<A-d>"] = open_file("rightbelow vnew"),
        -- GNOME Terminal sends Ctrl+Enter as Enter; Alt+Enter is distinct.
        ["<M-CR>"] = require("telescope.actions").select_vertical,
        ["<C-CR>"] = require("telescope.actions").select_vertical,
        -- Reuse the tab displaying this file, or open a new tab.
        ["<cr>"] = open_file("tab drop")
      },
      n = {
        ["<C-w>"] = require("telescope.actions").close,
        ["<A-w>"] = open_file("leftabove new"),
        ["<A-a>"] = open_file("leftabove vnew"),
        ["<A-s>"] = open_file("rightbelow new"),
        ["<A-d>"] = open_file("rightbelow vnew"),
        -- GNOME Terminal sends Ctrl+Enter as Enter; Alt+Enter is distinct.
        ["<M-CR>"] = require("telescope.actions").select_vertical,
        ["<C-CR>"] = require("telescope.actions").select_vertical,
        -- Also work in normal mode inside Telescope
        ["<cr>"] = open_file("tab drop")
      }
    }
  }
})

require("telescope").load_extension("fzf")

vim.keymap.set({ "n", "i" }, "<C-e>", "<cmd>Telescope find_files<CR>", {
  desc = "Find files",
})
-- Ctrl+D belongs to multiple-cursor selection.
vim.keymap.set("n", "<leader>b", "<cmd>Telescope buffers<CR>", {
  desc = "Search open buffers",
})

-- Navigate within this buffer; Enter should jump here rather than create a tab.
vim.keymap.set({ "n", "i", "x" }, "<A-l>", function()
  local builtin = require("telescope.builtin")
  local opts = {
    attach_mappings = function(_, map)
      local select = require("telescope.actions").select_default
      map("i", "<CR>", select)
      map("n", "<CR>", select)
      return true
    end,
  }
  opts.prompt_title = "Current file: search text"
  builtin.current_buffer_fuzzy_find(opts)
end, { desc = "Search all text in current file" })
