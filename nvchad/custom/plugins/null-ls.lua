local present, null_ls = pcall(require, "null-ls")

if not present then
  return
end

local b = null_ls.builtins

local sources = {
  -- Lua
  b.formatting.stylua,

  -- Markdown
  b.formatting.markdownlint,

  -- Go
  b.formatting.goimports,

  -- web development
  b.formatting.prettier,

  -- protobuf
  b.formatting.buf,
  b.diagnostics.buf,
}

null_ls.setup {
  debug = true,
  sources = sources,
}
