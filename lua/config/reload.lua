local M = {}

local function unload_prefix(prefix)
    local to_unload = {}

    for name in pairs(package.loaded) do
        if name == prefix or name:match("^" .. prefix:gsub("%.", "%%.") .. "\\.") then
            table.insert(to_unload, name)
        end
    end

    table.sort(to_unload, function(a, b)
        return #a > #b
    end)

    for _, name in ipairs(to_unload) do
        package.loaded[name] = nil
    end
end

local function reapply_filetype_autocmds()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local ft = vim.bo[buf].filetype
            if ft and ft ~= "" then
                vim.api.nvim_exec_autocmds("FileType", {
                    buffer = buf,
                    modeline = false,
                })
            end
        end
    end
end

function M.reload()
    local current = vim.api.nvim_buf_get_name(0)
    local config_root = vim.fn.stdpath("config")
    local plugin_spec_root = config_root .. "/lua/plugins/"

    unload_prefix("config")

    require("config.options")
    require("config.autocommands")
    require("config.mappings")
    require("config.breadcrumbs").setup()

    reapply_filetype_autocmds()
    vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
    vim.cmd("checktime")

    if current:sub(1, #plugin_spec_root) == plugin_spec_root then
        vim.notify(
            "Core config reloaded. For lua/plugins/* spec changes, lazy.nvim may still require :Lazy reload <plugin> or a restart.",
            vim.log.levels.WARN,
            { title = "Neovim config" }
        )
        return
    end

    vim.notify("Neovim core config reloaded", vim.log.levels.INFO, { title = "Neovim config" })
end

return M
