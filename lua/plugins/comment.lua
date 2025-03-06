return {
    "numToStr/Comment.nvim",
    opts = {
        -- add any options here
    },
    lazy = false,
    config = function()
        local comment = require("Comment")
        comment.setup()
    end,
}
