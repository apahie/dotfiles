local M = {}

M.plugins = {
  user = require("custom.plugins"),
  override = require("custom.override")
}

M.mappings = require("custom.mappings")



return M
