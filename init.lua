-- Autoformat on save
vim.cmd([[autocmd BufWritePre * lua vim.lsp.buf.format()]])

require("config.options")
require("config.mappings")
require("config.lazy")
require("config.autocommands")
