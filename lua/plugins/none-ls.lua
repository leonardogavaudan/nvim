return {
	"nvimtools/none-ls.nvim",
	branch = "main",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local null_ls = require("null-ls")

		local sources = {
			-- LUA
			null_ls.builtins.formatting.stylua,
			-- JS
			null_ls.builtins.formatting.prettier,
			-- PYTHON
			null_ls.builtins.formatting.black,
		}

		null_ls.setup({ sources = sources })
	end,
}
