-- Copy file path relative to git root
vim.keymap.set("n", "<leader>ph", function()
  local file_path = vim.fn.expand("%:p")
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]

  if git_root == nil or git_root == "" then
    print("Not a git repository")
    return
  end

  -- Ensure git root path ends with a slash
  if string.sub(git_root, -1) ~= "/" then
    git_root = git_root .. "/"
  end

  -- Calculate relative path from git root
  local relative_path = ""
  if string.sub(file_path, 1, string.len(git_root)) == git_root then
    relative_path = string.sub(file_path, string.len(git_root) + 1)
    vim.fn.setreg("+", relative_path)
    print("Copied relative path to clipboard: " .. relative_path)
  else
    print("File is not inside git root")
  end
end, { noremap = true, silent = true })
