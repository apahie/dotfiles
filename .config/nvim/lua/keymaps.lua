-- leader を Space に
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- 検索ハイライトをクリア
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "ハイライトをクリア" })

-- ウィンドウ移動
map("n", "<C-h>", "<C-w>h", { desc = "左ウィンドウへ" })
map("n", "<C-j>", "<C-w>j", { desc = "下ウィンドウへ" })
map("n", "<C-k>", "<C-w>k", { desc = "上ウィンドウへ" })
map("n", "<C-l>", "<C-w>l", { desc = "右ウィンドウへ" })

