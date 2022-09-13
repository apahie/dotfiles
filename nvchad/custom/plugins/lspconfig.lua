local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

-- :h lspconfig-all
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
local servers = {
  -- Markdown
  "marksman",

  -- Go
  "gopls",

  -- Rust
  "rust_analyzer",

  -- web development
  "html",
  "cssls",
  "tsserver",
  "emmet_ls",
  "jsonls",
  "eslint",
}

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end
