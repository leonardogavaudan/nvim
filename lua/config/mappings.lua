-----------------------------------------------------------
-- Mappings file
-----------------------------------------------------------

require("config.lsp-mappings") -- Import LSP-specific mappings
require("config.git-mappings") -- Import Git-specific mappings

-----------------------------------------------------------
-- File Explorer and Navigation
-----------------------------------------------------------
vim.keymap.set("n", "<leader>pv", "<CMD>Oil<CR>") -- Open netrw file explorer
vim.keymap.set("n", "<leader>cd", function() -- Change working directory to current file's directory
    vim.api.nvim_set_current_dir(vim.fn.expand("%:p:h"))
    print("Changed directory to: " .. vim.fn.getcwd())
end)

-----------------------------------------------------------
-- Clipboard and Register Operations
-----------------------------------------------------------
vim.keymap.set("v", "<leader>y", '"+y') -- Copy to system clipboard
vim.keymap.set("v", "<leader>p", '"_dP', { noremap = true, silent = true }) -- Paste without overwriting register
vim.keymap.set("v", "<leader>d", '"_d', { noremap = true, silent = true }) -- Delete without overwriting register

-----------------------------------------------------------
-- View and Search Operations
-----------------------------------------------------------
vim.keymap.set("n", ",", "<C-e>", { desc = "Move view down one line" }) -- Scroll view controls
vim.keymap.set("n", ".", "<C-y>", { desc = "Move view up one line" })
vim.keymap.set( -- Search and replace current visual selection
    "v",
    "<C-r>",
    '"hy:%s/<C-r>h//gc<left><left><left>',
    { noremap = true, silent = true, desc = "Search and replace selection" }
)

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("n", "<Leader>wh", function()
    local half_width = math.floor(vim.o.columns / 2)
    vim.cmd("vertical resize " .. half_width)
end, { noremap = true, silent = true, desc = "Resize buffer to half screen width" })
