return {
	"nvim-tree/nvim-web-devicons",
	branch = "master",
	config = function()
		local web_devicons = require("nvim-web-devicons")
		web_devicons.setup({
			default = true,
			strict = true,
		})
	end,
}
