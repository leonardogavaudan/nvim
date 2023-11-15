function OpenFileExternally()
  -- Get the current file's path using Netrw's internal variable
  local filepath = vim.fn.getline("."):gsub(" ", "\\ ")
  -- Execute the open command with the full file path
  vim.cmd('!open ' .. filepath)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', '<leader>o', ':lua OpenFileExternally()<CR>', { noremap = true, silent = true })
  end
})

