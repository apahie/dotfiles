local M = {}

M.general = {
  i = {
    ["<C-a>"] = { "<Home>", "beginning of line" },
    ["<C-e>"] = { "<End>", "end of line" },
    ["<C-b>"] = { "<Left>", "move left" },
    ["<C-f>"] = { "<Right>", "move right" },
    ["<C-n>"] = { "<Down>", "move down" },
    ["<C-p>"] = { "<Up>", "move up" },

    ["<C-j>"] = { "<C-o>o", "add new line below current line" },
    ["<C-k>"] = { "<C-o>O", "add new line above current line" },
  },
  c = {
    ["<C-a>"] = { "<Home>", "beginning of line" },
    ["<C-e>"] = { "<End>", "end of line" },
    ["<C-b>"] = { "<Left>", "move left" },
    ["<C-f>"] = { "<Right>", "move right" },
    ["<C-n>"] = { "<Down>", "move down" },
    ["<C-p>"] = { "<Up>", "move up" },
  },
}

M.disabled = {
  i = {
    ["<C-b>"] = "", -- { "<ESC>^i", "beginning of line" },
    ["<C-e>"] = "", -- { "<End>", "end of line" },
    ["<C-h>"] = "", -- { "<Left>", "move left" },
    ["<C-l>"] = "", -- { "<Right>", "move right" },
    ["<C-j>"] = "", -- { "<Down>", "move down" },
    ["<C-k>"] = "", -- { "<Up>", "move up" },
  },
  n = {
    ["<C-s>"] = "", -- { "<cmd> w <CR>", "save file" },
  },
}

M.hop = {
  n = {
    ["<leader>s"] = { "<cmd> HopChar1 <CR>", "type a key and hop to the char" },
  },
}

return M
