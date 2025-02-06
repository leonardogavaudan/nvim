vim.keymap.set("n", "<leader>t", function()
	if not vim.g.ai_provider then
		vim.g.ai_provider = "claude"
	end

	if vim.g.ai_provider == "claude" then
		vim.g.ai_provider = "openai"
		vim.cmd("AvanteSwitchProvider openai")
		print("Switched AI provider to openai")
	elseif vim.g.ai_provider == "openai" then
		vim.g.ai_provider = "openrouter"
		vim.cmd("AvanteSwitchProvider openrouter")
		print("Switched AI provider to openrouter")
	else
		vim.g.ai_provider = "claude"
		vim.cmd("AvanteSwitchProvider claude")
		print("Switched AI provider to claude")
	end
end, { desc = "Toggle AI Provider" })
