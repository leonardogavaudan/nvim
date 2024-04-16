-- Importing required modules for LSP setup
local lsp_zero = require('lsp-zero')
local lspconfig = require("lspconfig")
local cmp = require('cmp')
local lsp_inlayhints = require('lsp-inlayhints')

-- Setting up lsp-zero with recommended defaults and ensuring certain language servers are installed
lsp_zero.preset('recommended')
lsp_zero.ensure_installed({ 'tsserver', 'rust_analyzer', 'lua_ls' })

-- Fix Undefined global 'vim'
lsp_zero.nvim_workspace()

-- Initializing lsp-inlayhints for enhanced code readability
lsp_inlayhints.setup()

-- Configuring diagnostic sign icons for visual indication in the editor
lsp_zero.set_sign_icons({
	error = '✘',
	warn = '▲',
	hint = '⚑',
	info = '»'
})

-- Configuring Lua language server with specific settings to recognize 'vim' globals and disable telemetry
lsp_zero.configure('lua_ls', {
	settings = {
		Lua = {
			diagnostics = {
				globals = { 'vim' }
			}
		}
	}
})

-- Setting up completion (cmp) with custom key mappings for navigation and confirmation
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp_zero.defaults.cmp_mappings({
	['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
	['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
	['<C-y>'] = cmp.mapping.confirm({ select = true }),
	["<C-Space>"] = cmp.mapping.complete(),
})

-- Removing default Tab and Shift-Tab mappings for cmp
cmp_mappings['<Tab>'] = nil
cmp_mappings['<S-Tab>'] = nil

-- Applying the custom completion mappings
lsp_zero.setup_nvim_cmp({ mapping = cmp_mappings })


-- Setting LSP server suggestions preferences
lsp_zero.set_preferences({
	suggest_lsp_servers = true,
})


-- Customizing the on_attach function for key mappings related to LSP functions
lsp_zero.on_attach(function(_, bufnr)
	local opts = { buffer = bufnr, remap = false }

	vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
	vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
	vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
	vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
	vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
	vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
	vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
	vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
	vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
	vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
	vim.keymap.set("n", "<leader>k", function() vim.diagnostic.open_float() end, opts)
end)

-- Finalizing the lsp_zero setup
lsp_zero.setup()

-- Configuring diagnostic display options
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	update_in_insert = false,
	underline = true,
	severity_sort = false,
	float = true,
})


lspconfig.lua_ls.setup({
	on_attach = function(client, bufnr)
		lsp_inlayhints.on_attach(client, bufnr)
	end,
	settings = {
		Lua = {
			hint = {
				enable = true,
			},
			diagnostics = {
				globals = { 'vim' }
			}
		},
	},
})

local function setup_highlighting(client, bufnr)
	if client.server_capabilities.documentHighlightProvider then
		local augroup = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
		vim.api.nvim_create_autocmd("CursorHold", {
			callback = vim.lsp.buf.document_highlight,
			buffer = bufnr,
			group = augroup,
			desc = "Document Highlight",
		})
		vim.api.nvim_create_autocmd("CursorMoved", {
			callback = vim.lsp.buf.clear_references,
			buffer = bufnr,
			group = augroup,
			desc = "Clear All the References",
		})
	end
end

lspconfig.tsserver.setup({
	on_attach = function(client, bufnr)
		lsp_inlayhints.on_attach(client, bufnr)
		setup_highlighting(client, bufnr)
	end,
	settings = {
		javascript = {
			inlayHints = {
				includeInlayEnumMemberValueHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayParameterNameHints = 'all',
				includeInlayParameterNameHintsWhenArgumentMatchesName = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayVariableTypeHints = true,
			},
		},
		typescript = {
			inlayHints = {
				includeInlayEnumMemberValueHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayParameterNameHints = 'all',
				includeInlayParameterNameHintsWhenArgumentMatchesName = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayVariableTypeHints = true,
				importModuleSpecifierPreference = 'relative',
				importModuleSpecifierEnding = 'minimal',
			},
		},
	},
})

lspconfig.rust_analyzer.setup {
	on_attach = function(client, bufnr)
		lsp_inlayhints.on_attach(client, bufnr)
	end,
	settings = {
		['rust-analyzer'] = {
			hint = {
				enable = true,
			}
		}
	}
}
