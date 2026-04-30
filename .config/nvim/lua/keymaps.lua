-- leader を Space に
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- ファイル操作
map("n", "<leader>w", "<cmd>w<cr>", { desc = "保存" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "終了" })

-- 検索ハイライトをクリア
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "ハイライトをクリア" })

-- ウィンドウ移動
map("n", "<C-h>", "<C-w>h", { desc = "左ウィンドウへ" })
map("n", "<C-j>", "<C-w>j", { desc = "下ウィンドウへ" })
map("n", "<C-k>", "<C-w>k", { desc = "上ウィンドウへ" })
map("n", "<C-l>", "<C-w>l", { desc = "右ウィンドウへ" })
