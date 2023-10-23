vim.g.mapleader = " "  -- Set the leader key to space
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)  -- Execute :Ex in normal mode

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")  -- Move line(s) down in visual mode
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")  -- Move line(s) up in visual mode

vim.keymap.set("n", "J", "mzJ`z")  -- Join lines and restore cursor position in normal mode
vim.keymap.set("n", "<C-d>", "<C-d>zz")  -- Scroll down half a page and center cursor in normal mode
vim.keymap.set("n", "<C-u>", "<C-u>zz")  -- Scroll up half a page and center cursor in normal mode
vim.keymap.set("n", "n", "nzzzv")  -- Search next and center cursor in normal mode
vim.keymap.set("n", "N", "Nzzzv")  -- Search previous and center cursor in normal mode

vim.keymap.set("x", "<leader>p", [["_dP]])  -- Cut selected text and paste it before cursor, without altering the default register

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])  -- Yank text to system clipboard in normal and visual modes
vim.keymap.set("n", "<leader>Y", [["+Y]])  -- Yank line to system clipboard in normal mode

vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])  -- Delete text in normal or visual mode without affecting the default register

vim.keymap.set("i", "<C-c>", "<Esc>")  -- Map <C-c> in insert mode to exit insert mode (Escape)

vim.keymap.set("n", "Q", "<nop>")  -- Disable 'Q' in normal mode
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)  -- Format code in normal mode

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")  -- Go to the next compiler error and center cursor in normal mode
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")  -- Go to the previous compiler error and center cursor in normal mode
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")  -- Go to the next LSP error and center cursor in normal mode
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")  -- Go to the previous LSP error and center cursor in normal mode

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])  -- Search and replace word under cursor globally and interactively
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })  -- Make the current file executable

vim.keymap.set("n", "<leader>vpp", "<cmd>e ~/.dotfiles/nvim/.config/nvim/lua/theprimeagen/packer.lua<CR>")  -- Edit packer.lua file

vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end)  -- Source current file in normal mode
