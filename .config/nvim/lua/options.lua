-- 基本オプション
local opt = vim.opt

-- プラグイン動作に必要
opt.termguicolors = true        -- truecolor（カラースキームに必須）
opt.signcolumn = "yes"          -- gitsigns 等のサイン列を常時表示（横揺れ防止）

-- 一般的なデフォルト
opt.number = true               -- 絶対行番号
opt.expandtab = true            -- Tab はスペースに展開
opt.smartindent = true
opt.ignorecase = true           -- 検索は大文字小文字を区別しない
opt.smartcase = true            -- ただし大文字を含むときは区別する

-- スクロール余白（カーソル周囲に確保する行数）
opt.scrolloff = 8

-- 折り返し（コードを読むなら false 推奨）
opt.wrap = false

-- カーソル行のハイライト
opt.cursorline = true

-- ガイドライン（"100" で 100 列目に縦線）
opt.colorcolumn = "100"

-- インデント幅（tab/shift。例: 2 か 4）
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2

-- システムクリップボード連携（WSL でも動作）
opt.clipboard = "unnamedplus"
