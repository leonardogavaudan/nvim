require("null-ls").setup()
require("mason-null-ls").setup({
	ensure_installed = { "prettierd", "eslint" },
	automatic_setup = true,
        handlers = {}
})
