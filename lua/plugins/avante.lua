return {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change
    opts = {
        provider = "openai",
        claude = {
            endpoint = "https://api.anthropic.com",
            model = "claude-3-7-sonnet-20250219",
            temperature = 0,
            max_tokens = 4096,
        },
        openai = {
            endpoint = "https://api.openai.com/v1",
            model = "gpt-4o-2024-05-13",
            timeout = 30000,
            temperature = 0,
            max_tokens = 4096,
        },
        vendors = {
            openrouter = {
                __inherited_from = "openai",
                endpoint = "https://openrouter.ai/api/v1",
                api_key_name = "OPENROUTER_API_KEY",
                model = "qwen/qwq-32b",
                disable_tools = true,
                provider = {
                    order = { "Groq" },
                },
                reasoning = {
                    exclude = true,
                },
            },
        },
        rag_service = {
            enabled = false,
        },
        web_search_engine = {
            provider = "google", -- tavily, serpapi, searchapi, google or kagi
        },
        file_selector = {
            provider = function(params)
                require("telescope.builtin").find_files({
                    hidden = true,
                    search_dirs = params.cwd and { params.cwd } or nil,
                    find_command = { "fd", "--exclude", ".git" },
                    attach_mappings = function(_, map)
                        map("i", "<CR>", function(prompt_bufnr)
                            local selected = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
                            params.handler({ selected.value })
                            require("telescope.actions").close(prompt_bufnr)
                        end)
                        return true
                    end,
                })
            end,
        },
    },
    build = "make",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons",
        "zbirenbaum/copilot.lua",
        {
            "HakonHarnes/img-clip.nvim",
            event = "VeryLazy",
            opts = {
                default = {
                    embed_image_as_base64 = false,
                    prompt_for_file_name = false,
                    drag_and_drop = {
                        insert_mode = true,
                    },
                    use_absolute_path = true,
                },
            },
        },
        {
            "MeanderingProgrammer/render-markdown.nvim",
            opts = {
                file_types = { "Avante" },
            },
            ft = { "markdown", "Avante" },
        },
    },
}
