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

return {
	vscode,
}
