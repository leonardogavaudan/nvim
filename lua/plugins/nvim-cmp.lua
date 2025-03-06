return {
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp", -- LSP completions
            "hrsh7th/cmp-buffer", -- Buffer completions
            "hrsh7th/cmp-path", -- Path completions
        },
        config = function()
            local cmp = require("cmp")

            cmp.setup({
                completion = {
                    autocomplete = false, -- Disable automatic completion
                },
                mapping = {
                    ["<C-Space>"] = cmp.mapping.complete(), -- Trigger completion
                    ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Confirm selected item
                    ["<C-n>"] = cmp.mapping.select_next_item(), -- Navigate to next item
                    ["<C-p>"] = cmp.mapping.select_prev_item(), -- Navigate to previous item
                },
                sources = {
                    { name = "nvim_lsp" }, -- LSP completions
                    { name = "buffer" }, -- Buffer completions
                    { name = "path" }, -- Path completions
                },
            })
        end,
    },
}
