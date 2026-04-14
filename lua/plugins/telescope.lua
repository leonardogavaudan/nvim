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
        local make_entry = require("telescope.make_entry")

        local function only_filename_entry_maker(entry)
            local full_filename = entry.filename or entry.uri or entry.path or "[No file]"
            if full_filename:match("^%w+://") then
                full_filename = vim.uri_to_fname(full_filename)
            end

            local display_filename = full_filename
            local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
            if git_root and display_filename:sub(1, #git_root) == git_root then
                display_filename = display_filename:sub(#git_root + 2)
            end

            local text = entry.text or ""
            local ordinal = table.concat({ full_filename, tostring(entry.lnum or ""), tostring(entry.col or ""), text }, " ")

            return make_entry.set_default_entry_mt({
                value = entry,
                ordinal = ordinal,
                display = display_filename,
                filename = full_filename,
                lnum = entry.lnum,
                col = entry.col,
                text = text,
                start = entry.start,
                finish = entry.finish,
            }, {})
        end

        telescope.setup({
            defaults = {
                path_display = {},
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

        vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
        vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
        vim.keymap.set("n", "<Leader>ws", builtin.lsp_workspace_symbols, { desc = "Search workspace symbols" })
        vim.keymap.set("n", "<Leader>ds", builtin.lsp_document_symbols, { desc = "Search document symbols" })
        vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, opts)
    end,
}
