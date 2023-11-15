require("mason-null-ls").setup({
	ensure_installed = { "black", "prettier", "eslint-d" }
})

local null_ls = require("null-ls")

null_ls.setup({
	sources = {
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.prettier,
		null_ls.builtins.formatting.eslint,
	},
})

vim.keymap.set("n", "<leader>m", function()
	vim.lsp.buf.format()
end)

vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		vim.lsp.buf.format({ timeout_ms = 1000 })
	end,
})
