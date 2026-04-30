-- lazy.nvim ブートストラップ（初回のみ自動 clone）
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  ----------------------------------------------------------------
  -- 1. カラースキーム
  ----------------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",     -- night / storm / moon / day
      transparent = false,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  ----------------------------------------------------------------
  -- 2. 構文解析ベースのハイライト
  -- main ブランチ（実質旧 API）。新 API のリライトは現時点で撤退中
  ----------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc",
          "bash", "fish",
          "go", "javascript", "typescript", "tsx",
          "json", "yaml", "toml",
          "markdown", "markdown_inline",
          "java", "python",
          "terraform", "hcl",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  ----------------------------------------------------------------
  -- 3. ファイル / grep ファインダ
  ----------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "ファイル検索" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "全文 grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "バッファ一覧" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "ヘルプ検索" },
    },
    opts = {
      defaults = {
        file_ignore_patterns = { "%.git/" },  -- .git/ 配下は除外
      },
      pickers = {
        find_files = { hidden = true },        -- .git 以外の隠しファイルは表示
      },
    },
  },

  ----------------------------------------------------------------
  -- 4. git 差分（行頭サイン・blame）
  ----------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
  },

  ----------------------------------------------------------------
  -- 5. キーバインドのヘルプ表示（v3 系）
  ----------------------------------------------------------------
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
    },
  },
})
