return {
  ["williamboman/mason.nvim"] = {
    -- :Mason
    -- https://github.com/williamboman/mason.nvim/blob/main/PACKAGES.md
    ensure_installed = {
      -- lua
      "lua-language-server",
      "stylua",

      -- markdown
      "markdownlint",
      "marksman",

      -- go
      -- "go-debug-adapter",
      "goimports",
      "gopls",

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
