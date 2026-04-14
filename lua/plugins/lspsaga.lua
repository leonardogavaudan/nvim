return {
    "nvimdev/lspsaga.nvim",
    cmd = "Lspsaga",
    event = "LspAttach",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
    },
    opts = {
        lightbulb = {
            enable = false,
        },
        symbol_in_winbar = {
            enable = false,
        },
    },
    config = function(_, opts)
        require("lspsaga").setup(opts)
    end,
}
