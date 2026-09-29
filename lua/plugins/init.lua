-- ~/.config/nvim/lua/plugins/init.lua

-- Lazy.nvim setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- Plugin list
require("lazy").setup({
  -- Plugin manager
  "folke/lazy.nvim",

  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("plugins.catppuccin")
    end,
  },

  -- Automatically close brackets and quotes while typing.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("plugins.autopairs")
    end,
  },

  -- Formatting tools and file formatting.
  {
    "mason-org/mason.nvim",
    config = function()
      require("plugins.mason")
    end,
  },
  {
    "stevearc/conform.nvim",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      require("plugins.conform")
    end,
  },

  -- Select and edit matching words with multiple cursors.
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      require("plugins.multicursor")
    end,
  },

  -- Project-aware completion and automatic imports.
  {
    "neovim/nvim-lspconfig",
    dependencies = { "mason-org/mason.nvim", "saghen/blink.cmp" },
    config = function()
      require("plugins.lsp")
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("plugins.telescope")
    end
  },

   -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      {
        "nvim-tree/nvim-web-devicons",
        config = function()
          require("plugins.devicons")
        end,
      },
    },
    config = function()
      require("plugins.nerdtree")
    end
  },


  {
    "nvim-treesitter/nvim-treesitter",
    -- The default branch (main) is a rewrite requiring Neovim 0.12+.
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("plugins.treesitter")
    end
  },

  {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "rafamadriz/friendly-snippets" },
  config = function()
    require("plugins.blinkcmp")
  end,
  },

}, {
  -- Keep the checkout added by init.lua when stdpath('config') points elsewhere.
  performance = { rtp = { reset = false } },
})
