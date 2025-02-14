-- Default options for key mappings
local opts = { noremap = true, silent = true }

vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts) -- Go to definition of symbol under cursor
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- Go to declaration of symbol under cursor
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts) -- List all implementations of symbol under cursor
vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts) -- Go to type definition of symbol under cursor
vim.keymap.set("n", "K", vim.lsp.buf.hover, opts) -- Show hover information about symbol under cursor
vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts) -- Show signature help
vim.keymap.set("n", "gr", vim.lsp.buf.references, opts) -- List all references to symbol under cursor
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- Rename symbol under cursor
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- Show code actions available at current cursor position
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts) -- Show diagnostics in floating window
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- Jump to previous diagnostic
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- Jump to next diagnostic
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts) -- Add buffer diagnostics to the location list
-- vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts) -- Format current buffer -- ATTENTION now handled by conform
