return {
    "RRethy/vim-illuminate",
    branch = "master",
    config = function()
        require("illuminate").configure({
            delay = 200,
        })

        vim.keymap.set("n", "<leader>gn", function()
            require("illuminate").goto_next_reference(true) -- wrap enabled
        end, { noremap = true, silent = true })

        vim.keymap.set("n", "<leader>gp", function()
            require("illuminate").goto_prev_reference(true) -- wrap enabled
        end, { noremap = true, silent = true })

        vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
        vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
        vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
    end,
}
