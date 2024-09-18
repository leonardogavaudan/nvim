return {
	"lewis6991/gitsigns.nvim",
	branch = "main",
	config = function()
		local git_signs = require("gitsigns")
		git_signs.setup()
	end,
}
