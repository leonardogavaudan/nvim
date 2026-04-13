return {
    "yetone/avante.nvim",
    build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
        or "make",
    event = "VeryLazy",
    version = false,
    ---@module "avante"
    ---@type avante.Config
    opts = {
        instructions_file = "avante.md",
        provider = "codex",
        auto_suggestions_provider = nil,
        memory_summary_provider = nil,
        selector = {
            provider = "telescope",
        },
        windows = {
            width = 40,
            input = {
                height = 10,
            },
        },
        rag_service = {
            enabled = false,
        },
        acp_providers = {
            codex = {
                command = "npx",
                args = { "-y", "@zed-industries/codex-acp" },
                env = {
                    NODE_NO_WARNINGS = "1",
                    HOME = os.getenv("HOME"),
                    PATH = os.getenv("PATH"),
                },
                auth_method = "chatgpt",
            },
        },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-telescope/telescope.nvim",
        "hrsh7th/nvim-cmp",
        "nvim-tree/nvim-web-devicons",
        {
            "MeanderingProgrammer/render-markdown.nvim",
            ft = { "markdown", "Avante" },
            opts = {
                file_types = { "markdown", "Avante" },
            },
        },
    },
}
