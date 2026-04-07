return {
    "sindrets/diffview.nvim",
    config = function()
        local actions = require("diffview.actions")

        require("diffview").setup({
            keymaps = {
                view = {
                    ["J"] = actions.select_next_entry,
                    ["K"] = actions.select_prev_entry,
                    ["q"] = actions.close,
                    ["go"] = actions.goto_file_edit,
                    ["gs"] = actions.goto_file_split,
                    ["gt"] = actions.goto_file_tab,
                },
                file_panel = {
                    ["J"] = actions.select_next_entry,
                    ["K"] = actions.select_prev_entry,
                    ["q"] = actions.close,
                    ["go"] = actions.goto_file_edit,
                    ["gs"] = actions.goto_file_split,
                    ["gt"] = actions.goto_file_tab,
                },
            },
        })

        vim.keymap.set("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" })
        vim.keymap.set("n", "<leader>gf", "<cmd>DiffviewFocusFiles<cr>", { desc = "Focus Diffview files" })
        vim.keymap.set("n", "<leader>gb", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle Diffview files" })
    end,
}
