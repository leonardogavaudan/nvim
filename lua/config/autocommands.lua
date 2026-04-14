vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("default-indent-options", { clear = true }),
    pattern = "*",
    callback = function()
        vim.opt_local.tabstop = 2 -- Tabs appear as 2 spaces
        vim.opt_local.shiftwidth = 2 -- Indentation uses 2 spaces
        vim.opt_local.softtabstop = 2 -- Pasting and insert mode use 2 spaces
        vim.opt_local.expandtab = true -- Convert tabs to spaces
        vim.opt_local.list = false -- Do not show tabs/whitespace markers by default
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("python-lua-indent-options", { clear = true }),
    pattern = { "python", "lua" },
    callback = function()
        vim.opt_local.tabstop = 4 -- Tabs appear as 4 spaces
        vim.opt_local.shiftwidth = 4 -- Indentation uses 4 spaces
        vim.opt_local.softtabstop = 4 -- Pasting and insert mode use 4 spaces
        vim.opt_local.expandtab = true -- Convert tabs to spaces
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("go-indent-options", { clear = true }),
    pattern = { "go", "gomod", "gowork", "gotmpl" },
    callback = function()
        vim.opt_local.tabstop = 4 -- Render Go tabs as 4 spaces
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        vim.opt_local.expandtab = false -- Keep real tabs for Go formatting tools
    end,
})

-- Highlight when yanking (copying) text, see `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

local function apply_ui_highlights()
    vim.cmd([[ hi Normal guibg=NONE ctermbg=NONE ]]) -- For the background
    vim.cmd([[ hi NonText guibg=NONE ctermbg=NONE ]])
    vim.cmd([[
      highlight LineNr guibg=NONE ctermbg=NONE
    ]]) -- For the line numbers

    vim.cmd([[
      highlight SignColumn guibg=NONE ctermbg=NONE
      highlight EndOfBuffer guibg=NONE ctermbg=NONE
    ]]) -- Clears background on the left side that are not line numbers

    -- Diff colors: make adds/deletes obvious, but keep changed text neutral so
    -- argument additions/modifications do not look like deletions.
    -- Use mostly background-based diff highlights so syntax colors still show
    -- through in changed lines.
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#203A2A" })
    -- Keep deleted/filler areas aligned, but avoid a heavy red block background.
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "NONE", fg = "#C87C7C" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#1F2F4A" })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#35507A", bold = true })
end

-- Keep custom highlights after colorscheme changes and on startup.
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
    desc = "Apply transparent UI + custom diff highlights",
    group = vim.api.nvim_create_augroup("custom-ui-highlights", { clear = true }),
    callback = apply_ui_highlights,
})

-- Automatically reload files changed outside of Neovim
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    desc = "Auto-reload external file changes",
    group = vim.api.nvim_create_augroup("auto-reload", { clear = true }),
    callback = function()
        if vim.bo.buftype ~= "" then
            return
        end

        vim.cmd("checktime")
    end,
})
