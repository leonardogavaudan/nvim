-- LSP
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)
vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)

--

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, {})

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
