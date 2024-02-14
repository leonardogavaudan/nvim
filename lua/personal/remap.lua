-- Set the leader key to space
vim.g.mapleader = " "

-- File and buffer operations
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)                                                              -- Execute :Ex in normal mode
vim.keymap.set("n", "<leader>vpp", "<cmd>e ~/.dotfiles/nvim/.config/nvim/lua/theprimeagen/packer.lua<CR>") -- Edit packer.lua file
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end)                                      -- Source current file in normal mode

-- Cursor movement and window scrolling
vim.keymap.set("n", "J", "mzJ`z")                    -- Join lines and restore cursor position in normal mode
vim.keymap.set("n", "<C-d>", "<C-d>zz")              -- Scroll down half a page and center cursor in normal mode
vim.keymap.set("n", "<C-u>", "<C-u>zz")              -- Scroll up half a page and center cursor in normal mode
vim.keymap.set("n", ">", "jzz")                      -- Move cursor down one line and center in normal mode
vim.keymap.set("n", "<", "kzz")                      -- Move cursor up one line and center in normal mode
vim.keymap.set("n", ".", "<C-y>", { silent = true }) -- Scroll up one line without moving the cursor
vim.keymap.set("n", ",", "<C-e>", { silent = true }) -- Scroll down one line without moving the cursor

-- Search and navigation
vim.keymap.set("n", "n", "nzzzv")                                                        -- Search next and center cursor in normal mode
vim.keymap.set("n", "N", "Nzzzv")                                                        -- Search previous and center cursor in normal mode
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Search and replace word under cursor globally and interactively

-- Clipboard operations
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]]) -- Yank text to system clipboard in normal and visual modes
vim.keymap.set("n", "<leader>Y", [["+Y]])          -- Yank line to system clipboard in normal mode
vim.keymap.set("x", "<leader>p", [["_dP]])         -- Cut selected text and paste it before cursor, without altering the default register
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]]) -- Delete text in normal or visual mode without affecting the default register

-- Insert mode bindings
vim.keymap.set("i", "<C-c>", "<Esc>") -- Map <C-c> in insert mode to exit insert mode (Escape)

-- Error navigation
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")     -- Go to the next compiler error and center cursor in normal mode
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")     -- Go to the previous compiler error and center cursor in normal mode
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz") -- Go to the next LSP error and center cursor in normal mode
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz") -- Go to the previous LSP error and center cursor in normal mode

-- Visual mode line operations
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv") -- Move line(s) down in visual mode
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv") -- Move line(s) up in visual mode

-- Code formatting
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)                                 -- Format code in normal mode
vim.cmd([[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)]]) -- Auto format before saving

-- System operations
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true }) -- Make the current file executable

-- Disable unused keys
vim.keymap.set("n", "Q", "<nop>") -- Disable 'Q' in normal mode

-- Custom functionality
vim.keymap.set('n', '<leader>ph', function()
	local abs_path = vim.fn.expand("%:p:h") -- Get absolute path of current file's directory
	local file_name = vim.fn.expand("%:t") -- Get current file name
	local root_path = vim.fn.getcwd()      -- Get current working directory as project root

	-- Construct relative path from project root to file
	local rel_path = string.sub(abs_path, string.len(root_path) + 2) -- +2 to remove leading slash
	local complete_rel_path = rel_path .. '/' .. file_name          -- Complete relative path including file name

	-- Copy the relative path to the clipboard
	vim.cmd('let @* = "' .. complete_rel_path .. '"')
end)
