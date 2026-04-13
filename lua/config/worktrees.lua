local M = {}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Projects" })
end

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function abbreviate_home(path)
    local home = vim.fn.expand("~")
    if path:sub(1, #home) == home then
        return "~" .. path:sub(#home + 1)
    end

    return path
end

local function list_dirs(path)
    local matches = vim.fn.globpath(path, "*", false, true)
    local dirs = {}

    for _, match in ipairs(matches) do
        if vim.fn.isdirectory(match) == 1 then
            table.insert(dirs, match)
        end
    end

    return dirs
end

local function add_candidate(candidates, seen, path)
    if not path or path == "" or seen[path] then
        return
    end

    if vim.fn.isdirectory(path) ~= 1 then
        return
    end

    seen[path] = true
    table.insert(candidates, path)
end

local function current_git_repo_name()
    local cwd = vim.fn.getcwd()
    local result = vim.system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" }, { text = true }):wait()

    if result.code ~= 0 then
        return nil
    end

    local repo_root = trim(result.stdout)
    if repo_root == "" then
        return nil
    end

    return vim.fn.fnamemodify(repo_root, ":t")
end

local function current_git_worktrees()
    local cwd = vim.fn.getcwd()
    local result = vim.system({ "git", "-C", cwd, "worktree", "list", "--porcelain" }, { text = true }):wait()

    if result.code ~= 0 then
        return {}
    end

    local worktrees = {}
    for line in (result.stdout or ""):gmatch("[^\r\n]+") do
        local path = line:match("^worktree%s+(.+)$")
        if path then
            table.insert(worktrees, path)
        end
    end

    return worktrees
end

local function is_git_repo_root(path)
    local result = vim.system({ "git", "-C", path, "rev-parse", "--show-toplevel" }, { text = true }):wait()

    if result.code ~= 0 then
        return false
    end

    local repo_root = trim(result.stdout)
    if repo_root == "" then
        return false
    end

    local normalized_path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
    local normalized_repo = vim.fn.fnamemodify(repo_root, ":p"):gsub("/$", "")

    return normalized_path == normalized_repo
end

local function sort_candidates(candidates)
    local current_repo = current_git_repo_name()

    local function repo_rank(path)
        if not current_repo then
            return 1
        end

        local name = vim.fn.fnamemodify(path, ":t")
        if name == current_repo then
            return 0
        end

        if name:sub(1, #current_repo + 1) == current_repo .. "-" then
            return 0
        end

        return 1
    end

    table.sort(candidates, function(a, b)
        local a_rank = repo_rank(a)
        local b_rank = repo_rank(b)
        if a_rank ~= b_rank then
            return a_rank < b_rank
        end

        local a_name = vim.fn.fnamemodify(a, ":t")
        local b_name = vim.fn.fnamemodify(b, ":t")
        if a_name ~= b_name then
            return a_name < b_name
        end

        return a < b
    end)
end

local function list_worktrees()
    local candidates = {}
    local seen = {}

    for _, path in ipairs(list_dirs(vim.fn.expand("~/dev/worktrees"))) do
        add_candidate(candidates, seen, path)
    end

    for _, path in ipairs(current_git_worktrees()) do
        add_candidate(candidates, seen, path)
    end

    sort_candidates(candidates)
    return candidates
end

local function list_repos()
    local candidates = {}
    local seen = {}

    for _, path in ipairs(list_dirs(vim.fn.expand("~/dev"))) do
        if vim.fn.fnamemodify(path, ":t") ~= "worktrees" and is_git_repo_root(path) then
            add_candidate(candidates, seen, path)
        end
    end

    sort_candidates(candidates)
    return candidates
end

local function open_path(path, opts)
    opts = opts or {}

    if opts.new_tab then
        vim.cmd("tabnew")
    end

    local escaped = vim.fn.fnameescape(path)
    vim.cmd("tcd " .. escaped)

    if opts.open_files then
        require("telescope.builtin").find_files({
            cwd = path,
            prompt_title = "Files · " .. vim.fn.fnamemodify(path, ":t"),
        })
        return
    end

    vim.cmd("Oil " .. escaped)
end

local function pick_paths(opts)
    local ok_picker, pickers = pcall(require, "telescope.pickers")
    local ok_finder, finders = pcall(require, "telescope.finders")
    local ok_conf, conf = pcall(require, "telescope.config")
    local ok_actions, actions = pcall(require, "telescope.actions")
    local ok_state, action_state = pcall(require, "telescope.actions.state")

    if not (ok_picker and ok_finder and ok_conf and ok_actions and ok_state) then
        notify("Telescope is required for project picking", vim.log.levels.ERROR)
        return
    end

    local paths = opts.paths
    if #paths == 0 then
        notify(opts.empty_message, vim.log.levels.WARN)
        return
    end

    pickers
        .new({}, {
            prompt_title = opts.prompt_title .. " (<CR>=open dir, <C-f>=files, <C-t>=new tab)",
            finder = finders.new_table({
                results = paths,
                entry_maker = function(path)
                    local name = vim.fn.fnamemodify(path, ":t")
                    local display = string.format("%-35s %s", name, abbreviate_home(path))

                    return {
                        value = path,
                        display = display,
                        ordinal = table.concat({ name, path }, " "),
                    }
                end,
            }),
            sorter = conf.values.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                local function select(selection_opts)
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)

                    if selection and selection.value then
                        open_path(selection.value, selection_opts)
                    end
                end

                actions.select_default:replace(function()
                    select({})
                end)

                map("i", "<C-f>", function()
                    select({ open_files = true })
                end)
                map("n", "<C-f>", function()
                    select({ open_files = true })
                end)

                map("i", "<C-t>", function()
                    select({ new_tab = true })
                end)
                map("n", "<C-t>", function()
                    select({ new_tab = true })
                end)

                return true
            end,
        })
        :find()
end

function M.pick()
    pick_paths({
        paths = list_worktrees(),
        prompt_title = "Worktrees",
        empty_message = "No worktrees found in ~/dev/worktrees or current git repo",
    })
end

function M.pick_repos()
    pick_paths({
        paths = list_repos(),
        prompt_title = "Repos in ~/dev",
        empty_message = "No git repos found directly under ~/dev",
    })
end

return M
