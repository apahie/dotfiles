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
  -- master ブランチ（旧 API 維持・凍結）。main は完全リライト後 2026-04 に archived
  -- 公式後継 neovim/nvim-treeconfig (issue #39006) の実装を待つ間の暫定運用
  ----------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
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

  ----------------------------------------------------------------
  -- 6. ファイラ (サイドバー型ツリー)
  -- <leader>e でトグル。netrw は競合するため無効化
  ----------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "ファイルツリー" },
    },
    init = function()
      -- netrw は nvim-tree と競合するため無効化 (公式 README 推奨)
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
      filters = {
        dotfiles = false,  -- 隠しファイルも表示 (dotfiles 編集が多いため)
      },
    },
  },
})
