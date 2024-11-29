require("config.lsp-mappings")

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("v", "<leader>y", '"+y')

-- Get file path from git project root
vim.keymap.set("n", "<leader>ph", function()
	-- Get the full path of the current file
	local file_path = vim.fn.expand("%:p")

	-- Get the root directory of the git repository
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if git_root == nil or git_root == "" then
		print("Not a git repository")
		return
	end

	-- Ensure the git root path ends with a slash
	if string.sub(git_root, -1) ~= "/" then
		git_root = git_root .. "/"
	end

	-- Calculate the relative path from the git root to the current file
	local relative_path = ""
	if string.sub(file_path, 1, string.len(git_root)) == git_root then
		relative_path = string.sub(file_path, string.len(git_root) + 1)
	else
		print("File is not inside git root")
		return
	end

	-- Copy the relative path to the system clipboard
	vim.fn.setreg("+", relative_path)
	print("Copied relative path to clipboard: " .. relative_path)
end, { noremap = true, silent = true })

-- Paste without changing the register
vim.keymap.set("v", "<leader>p", '"_dP', { noremap = true, silent = true })
-- Delete without changing the register
vim.keymap.set("v", "<leader>d", '"_d', { noremap = true, silent = true })

-- Change director to current in netrw
vim.keymap.set("n", "<leader>cd", function()
	vim.api.nvim_set_current_dir(vim.fn.expand("%:p:h"))
end)

-- vim.keymap.set("n", ",", "jzz", { noremap = true, silent = true })
-- vim.keymap.set("n", ".", "kzz", { noremap = true, silent = true })
vim.keymap.set("n", ",", "<C-e>") -- Move view down one line
vim.keymap.set("n", ".", "<C-y>") -- Move view up one line

-- vim.api.nvim_set_keymap("v", "<C-r>", '"hy:%s/<C-r>h//gc<left><left><left>', { noremap = true, silent = true })
