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
