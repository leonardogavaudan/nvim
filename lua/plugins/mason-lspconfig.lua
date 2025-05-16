return {
    "williamboman/mason-lspconfig.nvim",
    branch = "main",
    config = function()
        local mason_lspconfig = require("mason-lspconfig")

        mason_lspconfig.setup({
            ensure_installed = { "lua_ls", "pyright", "ruff", "ts_ls", "clangd", "bashls", "vtsls", "gopls" },
        })
    end,
}
