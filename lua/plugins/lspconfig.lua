return {
    "neovim/nvim-lspconfig",
    config = function()
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        local uv = vim.uv or vim.loop

        local function path_exists(path)
            return uv.fs_stat(path) ~= nil
        end

        local function find_python_monorepo_root(path)
            local repo_root = vim.fs.root(path, { ".git" })
            if not repo_root then
                return nil
            end

            if path_exists(repo_root .. "/projects") and path_exists(repo_root .. "/requirements/dev.txt") then
                return repo_root
            end

            return nil
        end

        local function get_python_monorepo_python_path(root)
            local local_venv_python = root .. "/.venv/bin/python"
            if path_exists(local_venv_python) then
                return local_venv_python
            end

            local shared_venv_python = vim.fn.expand("~/dev/python/.venv/bin/python")
            if path_exists(shared_venv_python) then
                return shared_venv_python
            end

            return nil
        end

        local function find_vtsls_root(bufnr)
            local package_root = vim.fs.root(bufnr, { "tsconfig.json", "jsconfig.json", "package.json" })
            local workspace_root = vim.fs.root(bufnr, {
                "package-lock.json",
                "yarn.lock",
                "pnpm-lock.yaml",
                "bun.lockb",
                "bun.lock",
                ".git",
            })
            local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
            local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
            local project_root = package_root or workspace_root

            if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then
                return nil
            end

            if deno_root and (not project_root or #deno_root >= #project_root) then
                return nil
            end

            return project_root or vim.fn.getcwd()
        end

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
            root_dir = function(bufnr, on_dir)
                local fname = vim.api.nvim_buf_get_name(bufnr)
                if fname == "" then
                    return
                end

                local monorepo_root = find_python_monorepo_root(fname)
                if monorepo_root then
                    on_dir(monorepo_root)
                    return
                end

                local fallback_root = vim.fs.root(fname, {
                    "pyrightconfig.json",
                    "pyproject.toml",
                    "setup.py",
                    "setup.cfg",
                    "requirements.txt",
                    "Pipfile",
                    ".git",
                })

                if fallback_root then
                    on_dir(fallback_root)
                end
            end,
            before_init = function(_, config)
                local root = config.root_dir
                if not root then
                    return
                end

                local monorepo_root = find_python_monorepo_root(root)
                if not monorepo_root then
                    return
                end

                config.settings = config.settings or {}
                config.settings.python = config.settings.python or {}
                config.settings.python.analysis = config.settings.python.analysis or {}

                config.settings.python.analysis.extraPaths = {
                    monorepo_root .. "/projects",
                    monorepo_root,
                }

                local python_path = get_python_monorepo_python_path(monorepo_root)
                if python_path then
                    config.settings.python.pythonPath = python_path
                end
            end,
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
            root_dir = function(bufnr, on_dir)
                local root = find_vtsls_root(bufnr)
                if root then
                    on_dir(root)
                end
            end,
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

        -- CUE
        vim.lsp.config("cue", {
            capabilities = capabilities,
        })

        vim.lsp.enable({ "lua_ls", "ruff", "pyright", "vtsls", "clangd", "gopls", "bashls", "cue" })
    end,
}
