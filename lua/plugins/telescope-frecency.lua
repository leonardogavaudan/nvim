return {
  "nvim-telescope/telescope-frecency.nvim",
  config = function()
    local telescope = require("telescope")

    telescope.load_extension("frecency")

    vim.keymap.set("n", "<Leader>fF", function()
      telescope.extensions.frecency.frecency({})
    end)
  end,
}
