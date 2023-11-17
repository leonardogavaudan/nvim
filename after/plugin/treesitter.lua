require 'nvim-treesitter.configs'.setup {
	ensure_installed = { "vimdoc", "javascript", "typescript", "c", "lua", "rust" },
	sync_install = false,
	auto_install = true,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	textobjects = {
		-- This module is used for the text object mappings
		select = {
			enable = true,
			-- Automatically jump forward to textobj, similar to targets.vim
			lookahead = true,
			keymaps = {
				-- You can define your own textobjects like this...
				["af"] = "@function.outer",
				["if"] = "@function.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
			},
			goto_next_end = {
				["]M"] = "@function.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
			},
		},
	},
}

-- The following mappings depend on the `move` module from `nvim-treesitter/nvim-treesitter-textobjects`
local function move_and_center(key_sequence)
	-- Use nvim_feedkeys to simulate the key presses in normal mode.
	local keys = vim.api.nvim_replace_termcodes(key_sequence, true, false, true)
	vim.api.nvim_feedkeys(keys, 'n', true)
	-- Center the screen around the cursor after moving.
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('zz', true, false, true), 'n', true)
end

-- Map 'c' to go to the previous method and center
vim.keymap.set('n', 'C', function() move_and_center('[m') end, { noremap = true, silent = true })

-- Map 'r' to go to the next method and center
vim.keymap.set('n', 'R', function() move_and_center(']m') end, { noremap = true, silent = true })
