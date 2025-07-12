-----------------------------------------------------------
-- Mappings file
-----------------------------------------------------------

require("config.lsp-mappings") -- Import LSP-specific mappings
require("config.git-mappings") -- Import Git-specific mappings

-----------------------------------------------------------
-- File Explorer and Navigation
-----------------------------------------------------------
vim.keymap.set("n", "<leader>pv", "<CMD>Oil<CR>") -- Open netrw file explorer
vim.keymap.set("n", "<leader>cd", function()
    -- If inside an Oil buffer, use Oil's displayed directory
    if vim.bo.filetype == "oil" then
        local ok, oil = pcall(require, "oil")
        if ok and oil.get_current_dir then
            local dir = oil.get_current_dir()
            if dir and dir ~= "" then
                vim.api.nvim_set_current_dir(dir)
                print("Changed directory to: " .. dir)
                return
            end
        end
    end

    -- Otherwise, fall back to the current file's directory
    local path = vim.fn.expand("%:p:h")
    if path == "" or vim.fn.isdirectory(path) == 0 then
        vim.notify("No file-directory to cd into", vim.log.levels.WARN)
        return
    end
    local ok, err = pcall(vim.api.nvim_set_current_dir, path)
    if not ok then
        vim.notify("cd failed: " .. err, vim.log.levels.ERROR)
        return
    end
    print("Changed directory to: " .. vim.fn.getcwd())
end, { desc = "Change working directory intelligently (Oil aware)" })

-----------------------------------------------------------
-- Clipboard and Register Operations
-----------------------------------------------------------
vim.keymap.set("v", "<leader>y", '"+y') -- Copy to system clipboard
vim.keymap.set("v", "<leader>p", '"_dP', { noremap = true, silent = true }) -- Paste without overwriting register
vim.keymap.set("v", "<leader>d", '"_d', { noremap = true, silent = true }) -- Delete without overwriting register

-----------------------------------------------------------
-- View and Search Operations
-----------------------------------------------------------
vim.keymap.set("n", ",", "<C-e>", { desc = "Move view down one line" }) -- Scroll view controls
vim.keymap.set("n", ".", "<C-y>", { desc = "Move view up one line" })
vim.keymap.set( -- Search and replace current visual selection
    "v",
    "<C-r>",
    '"hy:%s/<C-r>h//gc<left><left><left>',
    { noremap = true, silent = true, desc = "Search and replace selection" }
)

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("n", "<Leader>wh", function()
    local half_width = math.floor(vim.o.columns / 2)
    vim.cmd("vertical resize " .. half_width)
end, { noremap = true, silent = true, desc = "Resize buffer to half screen width" })
