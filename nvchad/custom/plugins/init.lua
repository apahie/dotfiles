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
}
