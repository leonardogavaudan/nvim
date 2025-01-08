return {
  "nvimtools/none-ls.nvim",
  branch = "main",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local null_ls = require("null-ls")

    local sources = {
      -- LUA
      null_ls.builtins.formatting.stylua.with({
        extra_args = { "--indent-type", "Spaces", "--indent-width", "2" },
      }),
      -- JS
      null_ls.builtins.formatting.prettier,
      -- PYTHON
      null_ls.builtins.formatting.black,
      -- GO
      null_ls.builtins.formatting.gofmt,
      null_ls.builtins.formatting.goimports,
    }

    null_ls.setup({ sources = sources })
  end,
}
