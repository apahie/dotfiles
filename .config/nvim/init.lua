vim.g.mapleader = ' '

vim.opt.clipboard:append{'unnamedplus'}
vim.opt.syntax = 'ON'
vim.opt.number = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.scrolloff = 5
vim.opt.wildmode = 'list:longest'

vim.api.nvim_set_keymap('x', 'p', '"_dp', { noremap = true, silent = true })

vim.api.nvim_set_keymap('i', '<C-j>', '<C-o>o', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-k>', '<C-o>O', { noremap = true })

vim.api.nvim_set_keymap('i', '<C-p>', '<Up>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-n>', '<Down>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-b>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-f>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-a>', '<Home>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-e>', '<End>', { noremap = true })

vim.api.nvim_set_keymap('c', '<C-p>', '<Up>', { noremap = true })
vim.api.nvim_set_keymap('c', '<C-n>', '<Down>', { noremap = true })
vim.api.nvim_set_keymap('c', '<C-b>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('c', '<C-f>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('c', '<C-a>', '<Home>', { noremap = true })
vim.api.nvim_set_keymap('c', '<C-e>', '<End>', { noremap = true })

vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true })

require('plugins')
vim.cmd[[autocmd BufWritePost plugins.lua PackerCompile]]

