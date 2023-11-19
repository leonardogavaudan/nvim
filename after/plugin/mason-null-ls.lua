local mason_null_ls = require("mason-null-ls")
local null_ls = require("null-ls")

-- Setting up mason-null-ls with specified formatters to ensure they are installed
mason_null_ls.setup({
	ensure_installed = { "black", "prettier", "eslint-d" }
})

-- Configuring null-ls to use specific formatters
null_ls.setup({
	sources = {
		null_ls.builtins.formatting.black,  -- Python formatter
		null_ls.builtins.formatting.prettier, -- General purpose formatter
		null_ls.builtins.formatting.eslint_d.with({
			command = 'eslint_d',             -- ESLint with daemon for faster linting
		})
	},
})

-- Keymap for manually triggering formatting in normal mode
vim.keymap.set("n", "<leader>m", function()
	vim.lsp.buf.format({ timeout_ms = 2000 })
end)

-- Auto format before saving file
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		vim.lsp.buf.format({ timeout_ms = 1000 })
	end,
})
