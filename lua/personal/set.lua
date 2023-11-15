-- Basic editor display settings
vim.opt.nu = true             -- Enable line numbers
vim.opt.relativenumber = true -- Enable relative line number
vim.opt.wrap = false          -- Disable line wrapping
vim.opt.termguicolors = true  -- Enable terminal GUI colors
vim.opt.signcolumn = "yes"    -- Always show the sign column
vim.opt.colorcolumn = "80"    -- Set a text width marker at 80 characters
vim.opt.scrolloff = 8         -- Start scrolling when 8 lines away from margins

-- Indentation settings
vim.opt.tabstop = 2        -- Number of spaces a tab counts for
vim.opt.softtabstop = 2    -- Number of spaces in tab when editing
vim.opt.shiftwidth = 2     -- Number of spaces to use for each indent
vim.opt.expandtab = false  -- Use actual tab character for tabs
vim.opt.smartindent = true -- Enable smart indent

-- Search settings
vim.opt.hlsearch = false -- Disable search highlight
vim.opt.incsearch = true -- Enable incremental search

-- File backup and undo settings
vim.opt.swapfile = false                               -- Disable swap file creation
vim.opt.backup = false                                 -- Disable backup file creation
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir" -- Set directory for undo history files
vim.opt.undofile = true                                -- Enable persistent undo

-- Performance and usability settings
vim.opt.updatetime = 50       -- Reduce time before the swap file is written to disk
vim.opt.isfname:append("@-@") -- Allow '@' in filenames

