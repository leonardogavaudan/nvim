return {
    "yetone/avante.nvim",
    build = function()
        -- conditionally use the correct build system for the current OS
        if vim.fn.has("win32") == 1 then
            return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
        else
            return "make"
        end
    end,
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change
    --@module 'avante'
    --@type avant.Config
    opts = {
        provider = "openai",
        providers = {
            claude = {
                endpoint = "https://api.anthropic.com",
                model = "claude-sonnet-4-20250514",
            },
            openai = {
                endpoint = "https://api.openai.com/v1",
                model = "o3-2025-04-16",
            },
            aihubmix = {
                model = "gemini-2.5-flash-preview-05-20",
            },
            openrouter = {
                __inherited_from = "openai",
                endpoint = "https://openrouter.ai/api/v1",
                api_key_name = "OPENROUTER_API_KEY",
                model = "",
                disable_tools = false,
                reasoning = {
                    exclude = true,
                },
            },
        },
        rag_service = {
            enabled = true, -- Enables the RAG service
            host_mount = os.getenv("HOME"), -- Host mount path for the rag service
            provider = "openai", -- The provider to use for RAG service (e.g. openai or ollama)
            llm_model = "", -- The LLM model to use for RAG service
            embed_model = "", -- The embedding model to use for RAG service
            endpoint = "https://api.openai.com/v1", -- The API endpoint for RAG service
        },
        web_search_engine = {
            provider = "google", -- tavily, serpapi, searchapi, google or kagi
        },
        selector = {
            provider = function(selector)
                require("telescope.builtin").find_files({
                    prompt_title = selector.title or "Select file",
                    hidden = true,
                    find_command = { "fd", "--exclude", ".git" },
                    attach_mappings = function(_, map)
                        map("i", "<CR>", function(prompt_bufnr)
                            local selected = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
                            if selected and selector.on_select then
                                selector.on_select({ selected.value })
                            else
                                print("Warning: selector.on_select is nil or no file selected")
                            end
                            require("telescope.actions").close(prompt_bufnr)
                        end)
                        return true
                    end,
                })
            end,
        },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        --- The below dependencies are optional,
        "echasnovski/mini.pick", -- for file_selector provider mini.pick
        "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
        "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
        "ibhagwan/fzf-lua", -- for file_selector provider fzf
        "stevearc/dressing.nvim", -- for input provider dressing
        "folke/snacks.nvim", -- for input provider snacks
        "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        "zbirenbaum/copilot.lua", -- for providers='copilot'
        {
            -- support for image pasting
            "HakonHarnes/img-clip.nvim",
            event = "VeryLazy",
            opts = {
                -- recommended settings
                default = {
                    embed_image_as_base64 = false,
                    prompt_for_file_name = false,
                    drag_and_drop = {
                        insert_mode = true,
                    },
                    -- required for Windows users
                    use_absolute_path = true,
                },
            },
        },
        {
            -- Make sure to set this up properly if you have lazy=true
            "MeanderingProgrammer/render-markdown.nvim",
            opts = {
                file_types = { "markdown", "Avante" },
            },
            ft = { "markdown", "Avante" },
        },
    },
}
