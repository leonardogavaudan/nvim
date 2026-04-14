return {
    "sindrets/diffview.nvim",
    config = function()
        local actions = require("diffview.actions")

        local function expand_diff_windows_in_tab(tabpage)
            if not (tabpage and vim.api.nvim_tabpage_is_valid(tabpage)) then
                return
            end

            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
                if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
                    vim.api.nvim_win_call(win, function()
                        vim.cmd("setlocal nofoldenable")
                        pcall(vim.cmd, "normal! zR")
                    end)
                end
            end

            pcall(vim.api.nvim_tabpage_set_var, tabpage, "review_diff_context_expanded", true)
        end

        require("diffview").setup({
            hooks = {
                view_opened = function(view)
                    vim.schedule(function()
                        expand_diff_windows_in_tab(view.tabpage)
                    end)
                end,
            },
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
