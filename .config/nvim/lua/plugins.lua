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
  -- カラースキーム
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },

  -- 構文解析ベースのハイライト
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      -- パーサ install（バックグラウンドで非同期。再起動後に有効化）
      require("nvim-treesitter").install({
        "lua", "vim", "vimdoc",
        "bash", "fish",
        "go", "javascript", "typescript", "tsx",
        "json", "yaml", "toml",
        "markdown", "markdown_inline",
        "java", "python",
        "terraform", "hcl",
      })
      -- ファイル種別ごとにハイライト開始（パーサ未 install ならスキップ）
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },

  -- ファイル / grep ファインダ
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "ファイル検索" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "全文 grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "バッファ一覧" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "ヘルプ検索" },
    },
  },

  -- git 差分（行頭サイン）
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- キーバインドのヘルプ表示
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
})
