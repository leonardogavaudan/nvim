return {
	"nvim-telescope/telescope-frecency.nvim",
	config = function()
		local telescope = require("telescope")

		telescope.load_extension("frecency")

		vim.keymap.set("n", "<Leader>ff", function()
			telescope.extensions.frecency.frecency({})
		end)
	end,
}
