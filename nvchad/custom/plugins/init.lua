return {
  ["goolord/alpha-nvim"] = {
    disable = false,
  },

  ["phaazon/hop.nvim"] = {
    branch = "v2",
    config = function ()
      require("hop").setup()
    end
  },

  ["kylechui/nvim-surround"] = {
    config = function()
      require("nvim-surround").setup()
    end
  },

  ["neovim/nvim-lspconfig"] = {
      config = function()
        require("plugins.configs.lspconfig")
        require("custom.plugins.lspconfig")
      end,
  },
}
