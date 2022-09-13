return {
  ["williamboman/mason.nvim"] = {
    -- :Mason
    -- https://github.com/williamboman/mason.nvim/blob/main/PACKAGES.md
    ensure_installed = {
      -- Lua
      "lua-language-server",
      "stylua",

      -- Markdown
      "markdownlint",
      "marksman",

      -- Go
      -- "go-debug-adapter",
      "goimports",
      "gopls",

      -- Rust
      "rust-analyzer",

      -- web development
      "css-lsp",
      "html-lsp",
      "typescript-language-server",
      -- "deno",
      "emmet-ls",
      "json-lsp",
      "eslint-lsp",
      "prettier",

      -- protobuf
      "buf",
    },
  },

  ["kyazdani42/nvim-tree.lua"] = {
    git = {
      enable = true,
    },

    renderer = {
      highlight_git = true,
      icons = {
        show = {
          git = true,
        },
      },
    },
  },

  ["NvChad/nvterm"] = {
    behavior = {
      auto_insert = false,
    },
  },

  ["goolord/alpha-nvim"] = {
    header = {
      val = {
        "                                                     ",
        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
        "                                                     ",
      },
    },
  },
}
