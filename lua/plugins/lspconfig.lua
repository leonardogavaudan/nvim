return {
  "neovim/nvim-lspconfig",
  config = function()
    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

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
            library = vim.api.nvim_get_runtime_file("", true), -- Neovim runtime files
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })
    lspconfig.pyright.setup({
      capabilities = capabilities,
      on_attach = function()
        vim.opt.softtabstop = 4
        vim.opt.tabstop = 4
        vim.opt.shiftwidth = 4
      end,
    })
    lspconfig.ts_ls.setup({
      capabilities = capabilities,
    })
  end,
}
