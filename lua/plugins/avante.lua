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
            model = "gpt-4.1",
            timeout = 30000,
            temperature = 0,
            max_tokens = 4096,
        },
        aihubmix = {
            model = "gemini-2.5-flash-preview-05-20",
        },
        vendors = {
            openrouter = {
                __inherited_from = "openai",
                endpoint = "https://openrouter.ai/api/v1",
                api_key_name = "OPENROUTER_API_KEY",
                model = "google/gemini-2.5-flash-preview-05-20:thinking",
                disable_tools = true,
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
