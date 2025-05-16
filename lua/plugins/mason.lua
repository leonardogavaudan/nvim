return {
    "williamboman/mason.nvim",
    config = function()
        local mason = require("mason")
        mason.setup({
            ensure_installed = {
                "black",
                "ruff",
                "autopep8",
                "shfmt",
                "shellcheck",
                "clang-format",
                "stylua",
            },
            automatic_installation = true,
        })
    end,
}
