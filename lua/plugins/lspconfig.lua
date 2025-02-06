return {
	"neovim/nvim-lspconfig",
	config = function()
		local lspconfig = require("lspconfig")
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- LUA
		lspconfig.lua_ls.setup({
			capabilities = capabilities,
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
						path = vim.split(package.path, ";"),
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
					telemetry = {
						enable = false,
					},
					format = {
						enable = false,
					},
				},
			},
		})

		-- PYTHON
		-- Ruff for linting
		require("lspconfig").ruff.setup({
			init_options = {
				settings = {
					logLevel = "debug",
					fixAll = true,
					format = {
						indentStyle = "space",
						indentWidth = 4,
						lineEnding = "auto",
					},
				},
			},
		})

		-- Pyright for type checking and auto-imports
		require("lspconfig").pyright.setup({
			capabilities = capabilities,
			settings = {
				python = {
					analysis = {
						autoImportCompletions = true,
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						diagnosticMode = "workspace",
						typeCheckingMode = "basic",
					},
				},
			},
		})

		-- TYPESCRIPT
		lspconfig.ts_ls.setup({
			capabilities = capabilities,
			settings = {},
		})

		-- C
		lspconfig.clangd.setup({
			capabilities = capabilities,
		})

		-- GO
		lspconfig.gopls.setup({
			capabilities = capabilities,
			settings = {
				gopls = {
					analyses = {
						unusedparams = true,
					},
					staticcheck = true,
				},
			},
		})
	end,
}
