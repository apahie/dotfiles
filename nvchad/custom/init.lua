vim.opt.wildmode = "longest,list"

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = vim.lsp.buf.formatting_sync,
})
