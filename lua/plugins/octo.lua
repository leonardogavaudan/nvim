return {
    "pwntester/octo.nvim",
    requires = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
        -- OR 'ibhagwan/fzf-lua',
        -- OR 'folke/snacks.nvim',
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("octo").setup({
            mappings = {
                issue = {
                    next_file = { lhs = "<leader>n", desc = "Next file" },
                    prev_file = { lhs = "<leader>p", desc = "Previous file" },
                },
                pull_request = {
                    next_file = { lhs = "<leader>n", desc = "Next file" },
                    prev_file = { lhs = "<leader>p", desc = "Previous file" },
                },
                review_thread = {
                    select_next_entry = { lhs = "<leader>n", desc = "move to next changed file" },
                    select_prev_entry = { lhs = "<leader>p", desc = "move to previous changed file" },
                },
                review_diff = {
                    select_next_entry = { lhs = "<leader>n", desc = "move to next changed file" },
                    select_prev_entry = { lhs = "<leader>p", desc = "move to previous changed file" },
                },
                file_panel = {
                    select_next_entry = { lhs = "<leader>n", desc = "move to next changed file" },
                    select_prev_entry = { lhs = "<leader>p", desc = "move to previous changed file" },
                },
            },
        })
    end,
}
