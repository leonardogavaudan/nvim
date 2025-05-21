return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        local telescope = require("telescope")
        local builtin = require("telescope.builtin")

        local function only_filename_entry_maker(entry)
            local filename = entry.filename or entry.uri or entry.path or "[No file]"
            if filename:match("^%w+://") then
                filename = vim.uri_to_fname(filename)
            end
            -- Get git root
            local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
            if git_root and filename:sub(1, #git_root) == git_root then
                filename = filename:sub(#git_root + 2) -- +2 to remove the slash
            end
            return {
                value = entry,
                ordinal = filename,
                display = filename,
                filename = filename,
                lnum = entry.lnum,
            }
        end

        telescope.setup({
            defaults = {
                path_display = { "smart" },
                file_ignore_patterns = { ".git/" },
            },
            pickers = {
                find_files = {
                    hidden = true,
                },
                lsp_references = {
                    entry_maker = only_filename_entry_maker,
                },
            },
        })

        vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
        vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
        vim.keymap.set("n", "<Leader>ws", builtin.lsp_workspace_symbols, { desc = "Search workspace symbols" })
        vim.keymap.set("n", "<Leader>ds", builtin.lsp_document_symbols, { desc = "Search document symbols" })
        vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, opts)
    end,
}
