return {
    "dmtrKovalenko/fff.nvim",
    lazy = false,
    build = function()
        local done = false
        local err = nil

        require("fff.download").download_binary(function(success, download_err)
            if not success then
                err = download_err or "unknown error"
            end
            done = true
        end)

        local ok, wait_err = vim.wait(1000 * 60 * 2, function()
            return done
        end, 100)

        if not ok and wait_err == -2 then
            error("fff.nvim: prebuilt binary download timed out")
        end

        if err then
            error("fff.nvim: failed to download prebuilt binary: " .. err)
        end
    end,
    opts = {
        lazy_sync = true,
    },
    keys = {
        {
            "<leader>ff",
            function()
                require("fff").find_files_in_dir(vim.fn.getcwd())
            end,
            desc = "Find files in cwd (FFF)",
        },
    },
}
