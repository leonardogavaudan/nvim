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

-- Highlight when yanking (copying) text, see `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Force transparent BG
vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Force transparent BG when entering files, in case config didn't set properly.",
  callback = function()
    vim.cmd([[ hi Normal guibg=NONE ctermbg=NONE ]]) -- For the background
    vim.cmd([[ hi NonText guibg=NONE ctermbg=NONE ]])
    vim.cmd([[
      highlight LineNr guibg=NONE ctermbg=NONE
    ]]) -- For the line numbers

    vim.cmd([[
      highlight SignColumn guibg=NONE ctermbg=NONE
      highlight EndOfBuffer guibg=NONE ctermbg=NONE
    ]]) -- Clears background on the left side that are not line numbers
  end,
})
