-- Lua モジュールロードを高速化（Neovim 0.9+）
vim.loader.enable()

-- 基本設定とプラグインを読み込む
require("options")
require("keymaps")
require("plugins")

-- work overlay があれば読み込む（無くても OK）
pcall(require, "work")
