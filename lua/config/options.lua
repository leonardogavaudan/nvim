vim.g.mapleader = " " -- Set leader key to space
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers

vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 2 -- Number of spaces tabs count for
vim.opt.shiftwidth = 2 -- Size of an indent
vim.opt.softtabstop = 2 -- Number of spaces that a <Tab> counts for

vim.opt.cursorline = true -- Highlight current line
vim.opt.signcolumn = "yes" -- Always show sign column

vim.opt.list = true -- Show some invisible characters
vim.opt.listchars = { tab = "» " } -- Configure invisible characters

vim.opt.ignorecase = true -- Ignore case in search patterns
vim.opt.smartcase = true -- Override ignorecase if search pattern contains uppercase
vim.opt.incsearch = true -- Show search matches as you type
vim.opt.hlsearch = true -- Highlight all matches of the search pattern
