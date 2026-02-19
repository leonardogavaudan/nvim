return {
    "neovim/nvim-lspconfig",
    config = function()
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        -- LUA
        vim.lsp.config("lua_ls", {
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
        vim.lsp.config("ruff", {
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
        vim.lsp.config("pyright", {
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
        vim.lsp.config("vtsls", {
            capabilities = capabilities,
            settings = {
                vtsls = {
                    enableMoveToFileCodeAction = true,
                },
            },
            commands = {
                -- Register the custom command handler for move to file refactoring
                ["_typescript.moveToFileRefactoring"] = function(command, ctx)
                    require("config.vtsls-handlers").handle_move_to_file(command, ctx)
                end,
            },
        })

        -- C
        vim.lsp.config("clangd", {
            capabilities = capabilities,
        })

        -- GO
        vim.lsp.config("gopls", {
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

        -- BASH
        vim.lsp.config("bashls", {
            settings = {
                bashIde = {
                    shellcheckPath = "shellcheck",
                    enableSourceErrorDiagnostics = true,
                },
            },
        })

        vim.lsp.enable({ "lua_ls", "ruff", "pyright", "vtsls", "clangd", "gopls", "bashls" })
    end,
}
