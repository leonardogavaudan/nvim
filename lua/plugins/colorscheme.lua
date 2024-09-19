local gruvbox = {
	"luisiacc/gruvbox-baby",
	branch = "main",
	lazy = false,
	priority = 1000,
	config = function()
		vim.cmd([[colorscheme gruvbox-baby]])
	end,
}

local vscode = {
	"Mofiqul/vscode.nvim",
	branch = "main",
	lazy = false,
	priority = 1000,
	config = function()
		vim.cmd([[colorscheme vscode]])
	end,
}

local github = {
	"projekt0n/github-nvim-theme",
	lazy = false, -- make sure we load this during startup if it is your main colorscheme
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function()
		require("github-theme").setup({})
		vim.cmd("colorscheme github_dark_dimmed")
	end,
}

local kanagawa = {
	"rebelot/kanagawa.nvim",
	branch = "master",
	config = function()
		vim.cmd("colorscheme kanagawa")
	end,
}

return {
	github,
}
