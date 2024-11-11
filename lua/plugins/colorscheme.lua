local function set_background()
	-- Set Normal and NonText groups to transparent
	vim.cmd([[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NonText guibg=NONE ctermbg=NONE
]])

	-- To make line numbers transparent, you can set LineNr as well
	vim.cmd([[
  highlight LineNr guibg=NONE ctermbg=NONE
]])

	-- Optionally, set other elements to transparent if needed
	vim.cmd([[
  highlight SignColumn guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
]])
end

local gruvbox = {
	"luisiacc/gruvbox-baby",
	branch = "main",
	lazy = false,
	priority = 1000,
	config = function()
		vim.cmd([[colorscheme gruvbox-baby]])
		set_background()
	end,
}

local vscode = {
	"Mofiqul/vscode.nvim",
	branch = "main",
	lazy = false,
	priority = 1000,
	config = function()
		vim.cmd([[colorscheme vscode]])
		set_background()
	end,
}

local github = {
	"projekt0n/github-nvim-theme",
	lazy = false, -- make sure we load this during startup if it is your main colorscheme
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function()
		require("github-theme").setup({})
		-- vim.cmd("colorscheme github_dark_dimmed")
		vim.cmd("colorscheme github_dark_default")
		set_background()
	end,
}

local kanagawa = {
	"rebelot/kanagawa.nvim",
	branch = "master",
	config = function()
		vim.cmd("colorscheme kanagawa")
		set_background()
	end,
}

return {
	-- github,
	-- gruvbox,
	vscode,
}
