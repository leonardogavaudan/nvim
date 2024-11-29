vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt.tabstop = 2 -- Tabs appear as 2 spaces
    vim.opt.shiftwidth = 2 -- Indentation uses 2 spaces
    vim.opt.softtabstop = 2 -- Pasting and insert mode use 2 spaces
    vim.opt.expandtab = true -- Convert tabs to spaces
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt.tabstop = 4 -- Tabs appear as 4 spaces
    vim.opt.shiftwidth = 4 -- Indentation uses 4 spaces
    vim.opt.softtabstop = 4 -- Pasting and insert mode use 4 spaces
    vim.opt.expandtab = true -- Convert tabs to spaces
  end,
})

-- Format before saving
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
