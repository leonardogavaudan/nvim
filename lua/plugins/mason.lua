return {
	"williamboman/mason.nvim",
	config = function()
		local mason = require("mason")
		mason.setup({
			ensure_installed = {
				-- Formatters
				"black",
				"ruff",
				"autopep8",
			},
			automatic_installation = true,
		})
	end,
}
