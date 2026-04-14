local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Git PR Review" })
end

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function format_iso_date_to_ymd(iso_time)
    if type(iso_time) ~= "string" then
        return "----/--/--"
    end

    local year, month, day = iso_time:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
    if not year then
        return "----/--/--"
    end

    return ("%s/%s/%s"):format(year, month, day)
end

local function run(args, opts)
    local result = vim.system(args, {
        cwd = opts and opts.cwd or nil,
        text = true,
    }):wait()

    if result.code ~= 0 then
        local err = trim(result.stderr)
        if err == "" then
            err = trim(result.stdout)
        end
        if err == "" then
            err = ("Command failed: %s"):format(table.concat(args, " "))
        end
        return nil, err
    end

    return result.stdout or ""
end

local function parse_owner_repo_from_remote(remote)
    if remote == "" then
        return nil
    end

    local owner_repo = remote:match("github%.com[:/]([%w%._%-]+/[%w%._%-]+)%.git$")
        or remote:match("github%.com[:/]([%w%._%-]+/[%w%._%-]+)$")

    return owner_repo
end

local function get_repo_context()
    local git_root_out = run({ "git", "rev-parse", "--show-toplevel" }, { cwd = vim.fn.getcwd() })
    if not git_root_out then
        return nil
    end

    local git_root = trim(git_root_out)

    local remote_out = run({ "git", "config", "--get", "remote.origin.url" }, { cwd = git_root })
    local owner_repo = remote_out and parse_owner_repo_from_remote(trim(remote_out)) or nil

    if not owner_repo then
        local gh_repo_out = run(
            { "gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner" },
            { cwd = git_root }
        )
        if gh_repo_out then
            owner_repo = trim(gh_repo_out)
        end
    end

    if not owner_repo then
        return nil
    end

    return {
        git_root = git_root,
        owner_repo = owner_repo,
    }
end

local function repo_from_pr(pr)
    if pr.repository and pr.repository.nameWithOwner and pr.repository.nameWithOwner ~= "" then
        return pr.repository.nameWithOwner
    end

    if pr.url then
        local from_url = pr.url:match("github%.com/([^/]+/[^/]+)/pull/%d+")
        if from_url then
            return from_url
        end
    end

    return nil
end

local function normalize_path(path)
    return vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
end

local function repo_name_from_owner_repo(owner_repo)
    return owner_repo:match("/([^/]+)$")
end

local function ensure_local_repo(owner_repo, repo_context)
    if repo_context and repo_context.owner_repo == owner_repo then
        return repo_context.git_root
    end

    local repo_name = repo_name_from_owner_repo(owner_repo)
    if not repo_name then
        return nil, ("Could not parse repository name from %s"):format(owner_repo)
    end

    local target_dir = vim.fn.expand("~/dev/" .. repo_name)

    if vim.fn.isdirectory(target_dir) == 1 then
        local is_git_repo_out = run({ "git", "rev-parse", "--is-inside-work-tree" }, { cwd = target_dir })
        if is_git_repo_out and trim(is_git_repo_out) == "true" then
            return target_dir
        end
        return nil, ("Directory exists but is not a git repo: %s"):format(target_dir)
    end

    notify(("Cloning %s into %s"):format(owner_repo, target_dir))

    local _, clone_err = run({ "gh", "repo", "clone", owner_repo, target_dir })
    if clone_err then
        return nil, clone_err
    end

    return target_dir
end

local function registered_worktrees(repo_path)
    run({ "git", "worktree", "prune" }, { cwd = repo_path })

    local out, err = run({ "git", "worktree", "list", "--porcelain" }, { cwd = repo_path })
    if not out then
        return nil, err
    end

    local worktrees = {}
    for line in out:gmatch("[^\r\n]+") do
        local path = line:match("^worktree%s+(.+)$")
        if path then
            worktrees[normalize_path(path)] = true
        end
    end

    return worktrees
end

local function copy_agents_local_files(source_repo, worktree_path)
    local out, err = run({ "fd", "-H", "-I", "-t", "f", "-g", "AGENTS.local.md", "." }, { cwd = source_repo })
    if not out then
        return err
    end

    local source_root = normalize_path(source_repo)
    local worktree_root = normalize_path(worktree_path)

    for rel_path in out:gmatch("[^\r\n]+") do
        if rel_path ~= "" then
            local src = source_root .. "/" .. rel_path
            local dst = worktree_root .. "/" .. rel_path
            vim.fn.mkdir(vim.fn.fnamemodify(dst, ":h"), "p")

            local _, copy_err = run({ "cp", src, dst })
            if copy_err then
                return copy_err
            end
        end
    end

    return nil
end

local function copy_global_ignored_files(source_repo, worktree_path)
    local manifest_path = vim.fn.expand("~/.config/nix-darwin/scripts/worktree-copy-global-ignored/Cargo.toml")
    local _, err = run({
        "cargo",
        "run",
        "--quiet",
        "--manifest-path",
        manifest_path,
        "--",
        "--source",
        normalize_path(source_repo),
        "--worktree",
        normalize_path(worktree_path),
    }, { cwd = source_repo })

    return err
end

local function ensure_review_worktree(repo_path, owner_repo, pr_number, base_ref)
    local repo_name = repo_name_from_owner_repo(owner_repo)
    if not repo_name then
        return nil, ("Could not parse repository name from %s"):format(owner_repo)
    end

    local worktree_path = normalize_path(vim.fn.expand("~/dev/worktrees/" .. repo_name .. "-review-pr-" .. tostring(pr_number)))
    local worktrees, worktrees_err = registered_worktrees(repo_path)
    if not worktrees then
        return nil, worktrees_err
    end

    if not worktrees[worktree_path] then
        if vim.fn.isdirectory(worktree_path) == 1 then
            return nil, ("Directory exists but is not a registered worktree: %s"):format(worktree_path)
        end

        local _, add_err = run({ "git", "worktree", "add", "--detach", worktree_path, "origin/" .. base_ref }, { cwd = repo_path })
        if add_err then
            return nil, add_err
        end

        local agents_err = copy_agents_local_files(repo_path, worktree_path)
        if agents_err then
            notify(("Created review worktree, but copying AGENTS.local.md failed: %s"):format(agents_err), vim.log.levels.WARN)
        end

        local ignored_err = copy_global_ignored_files(repo_path, worktree_path)
        if ignored_err then
            notify(("Created review worktree, but copying global ignored files failed: %s"):format(ignored_err), vim.log.levels.WARN)
        end
    end

    return worktree_path
end

local function open_url(url)
    if not url or url == "" then
        return
    end

    if vim.ui and vim.ui.open then
        vim.ui.open(url)
        return
    end

    vim.fn.system({ "open", url })
end

local function checkout_and_open_diff(pr, repo_context)
    local owner_repo = repo_from_pr(pr)
    if not owner_repo then
        notify("Could not resolve repository for selected PR", vim.log.levels.ERROR)
        open_url(pr.url)
        return
    end

    local repo_path, repo_err = ensure_local_repo(owner_repo, repo_context)
    if not repo_path then
        notify(("No local clone for %s: %s"):format(owner_repo, repo_err), vim.log.levels.ERROR)
        open_url(pr.url)
        return
    end

    local base_out, base_err = run({
        "gh",
        "pr",
        "view",
        tostring(pr.number),
        "--repo",
        owner_repo,
        "--json",
        "baseRefName",
        "--jq",
        ".baseRefName",
    }, { cwd = repo_path })
    if not base_out then
        notify(("Could not resolve base branch: %s"):format(base_err), vim.log.levels.ERROR)
        open_url(pr.url)
        return
    end

    local base_ref = trim(base_out)
    if base_ref == "" then
        notify("PR base branch is empty", vim.log.levels.ERROR)
        open_url(pr.url)
        return
    end

    local _, fetch_err = run({ "git", "fetch", "origin", base_ref }, { cwd = repo_path })
    if fetch_err then
        notify(("Failed to fetch origin/%s: %s"):format(base_ref, fetch_err), vim.log.levels.ERROR)
        open_url(pr.url)
        return
    end

    local worktree_path, worktree_err = ensure_review_worktree(repo_path, owner_repo, pr.number, base_ref)
    if not worktree_path then
        notify(("Failed to prepare review worktree for %s#%d: %s"):format(owner_repo, pr.number, worktree_err), vim.log.levels.ERROR)
        open_url(pr.url)
        return
    end

    local _, checkout_err = run(
        { "gh", "pr", "checkout", tostring(pr.number), "--repo", owner_repo, "--detach" },
        { cwd = worktree_path }
    )
    if checkout_err then
        notify(("Failed to checkout %s#%d in %s: %s"):format(owner_repo, pr.number, worktree_path, checkout_err), vim.log.levels.ERROR)
        open_url(pr.url)
        return
    end

    vim.cmd("tcd " .. vim.fn.fnameescape(worktree_path))
    vim.t.review_base_ref = base_ref
    vim.t.review_repo_root = normalize_path(worktree_path)
    vim.t.review_owner_repo = owner_repo
    vim.t.review_pr_number = pr.number
    pcall(vim.cmd, "DiffviewClose")
    vim.cmd("Oil " .. vim.fn.fnameescape(worktree_path))

    notify(
        (
            "Checked out %s#%d in %s (base: %s). Use <leader>gc for changed files, or :DiffviewOpen origin/%s...HEAD if you want the diff view."
        ):format(owner_repo, pr.number, worktree_path, base_ref, base_ref)
    )
end

local function current_repo_root()
    local git_root_out = run({ "git", "rev-parse", "--show-toplevel" }, { cwd = vim.fn.getcwd() })
    if not git_root_out then
        return nil
    end

    local git_root = trim(git_root_out)
    if git_root == "" then
        return nil
    end

    return git_root
end

local function resolve_base_ref(repo_root)
    local normalized_repo_root = normalize_path(repo_root)

    if vim.t.review_base_ref and vim.t.review_repo_root and normalize_path(vim.t.review_repo_root) == normalized_repo_root then
        return vim.t.review_base_ref, false
    end

    local out = run({ "git", "symbolic-ref", "refs/remotes/origin/HEAD" }, { cwd = repo_root })
    if not out then
        return nil, nil
    end

    local base_ref = trim(out):gsub("^refs/remotes/origin/", "")
    if base_ref == "" then
        return nil, nil
    end

    return base_ref, true
end

local function split_lines(text)
    local lines = vim.split(text or "", "\n", { plain = true })
    if #lines > 0 and lines[#lines] == "" then
        table.remove(lines, #lines)
    end
    return lines
end

local function changed_files_against_base(repo_root, base_ref)
    local out, err = run({ "git", "diff", "--name-status", "--find-renames", "origin/" .. base_ref .. "...HEAD" }, { cwd = repo_root })
    if not out then
        return nil, err
    end

    local entries = {}
    for line in out:gmatch("[^\r\n]+") do
        local parts = vim.split(line, "\t", { plain = true })
        local status = parts[1]
        local status_code = status and status:sub(1, 1) or nil

        if status_code == "R" or status_code == "C" then
            if parts[2] and parts[3] then
                table.insert(entries, {
                    status = status,
                    status_code = status_code,
                    base_path = parts[2],
                    path = parts[3],
                })
            end
        elseif status_code and parts[2] then
            table.insert(entries, {
                status = status,
                status_code = status_code,
                base_path = parts[2],
                path = parts[2],
            })
        end
    end

    return entries
end

local function scratch_title(prefix, path)
    return string.format("%s %s", prefix, path)
end

local function configure_scratch_buffer(buf, title, lines, filename_hint)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = true
    pcall(vim.api.nvim_buf_set_name, buf, title)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].modified = false

    local detected = vim.filetype.match({ filename = filename_hint })
    if detected and detected ~= "" then
        vim.bo[buf].filetype = detected
    end
end

local function load_base_lines(repo_root, entry, base_ref)
    if entry.status_code == "A" then
        return {}
    end

    local out, err = run({ "git", "show", "origin/" .. base_ref .. ":" .. entry.base_path }, { cwd = repo_root })
    if out then
        return split_lines(out)
    end

    notify(("Could not load base version of %s: %s"):format(entry.base_path, err), vim.log.levels.WARN)
    return {}
end

local function absolute_repo_path(repo_root, rel_path)
    return normalize_path(repo_root) .. "/" .. rel_path
end

local function clear_review_diff_state()
    vim.t.review_diff_left_win = nil
    vim.t.review_diff_right_win = nil
    vim.t.review_diff_rel_path = nil
    vim.t.review_diff_context_expanded = nil
end

local function save_current_view()
    return vim.fn.winsaveview()
end

local function restore_view_in_win(win, view)
    if not (view and win and vim.api.nvim_win_is_valid(win)) then
        return
    end

    vim.api.nvim_win_call(win, function()
        pcall(vim.fn.winrestview, view)
    end)
end

local function diff_windows_in_current_tab()
    local wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
            table.insert(wins, win)
        end
    end
    return wins
end

local function clear_diff_word_highlights()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_call(win, function()
                if vim.w.review_diff_word_match_id then
                    pcall(vim.fn.matchdelete, vim.w.review_diff_word_match_id)
                    vim.w.review_diff_word_match_id = nil
                end
            end)
        end
    end

    vim.t.review_diff_highlight_word = nil
end

local function current_diff_word()
    if not vim.wo.diff then
        return nil
    end

    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col(".")
    local char = line:sub(col, col)

    if char == "" or not char:match("[%w_]") then
        return nil
    end

    local word = vim.fn.expand("<cword>")
    if not word or word == "" then
        return nil
    end

    return word
end

local function update_diff_word_highlights()
    local diff_wins = diff_windows_in_current_tab()
    if #diff_wins == 0 or not vim.wo.diff then
        clear_diff_word_highlights()
        return
    end

    local word = current_diff_word()
    if not word then
        clear_diff_word_highlights()
        return
    end

    if vim.t.review_diff_highlight_word == word then
        return
    end

    local pattern = [[\V\<]] .. vim.fn.escape(word, [[\]]) .. [[\>]]
    for _, win in ipairs(diff_wins) do
        vim.api.nvim_win_call(win, function()
            if vim.w.review_diff_word_match_id then
                pcall(vim.fn.matchdelete, vim.w.review_diff_word_match_id)
            end
            vim.w.review_diff_word_match_id = vim.fn.matchadd("IlluminatedWordText", pattern, 10)
        end)
    end

    vim.t.review_diff_highlight_word = word
end

local function set_diff_context_expanded(expanded)
    local diff_wins = diff_windows_in_current_tab()
    if #diff_wins == 0 then
        notify("No diff windows in the current tab", vim.log.levels.WARN)
        return
    end

    local current_win = vim.api.nvim_get_current_win()
    for _, win in ipairs(diff_wins) do
        vim.api.nvim_set_current_win(win)
        if expanded then
            vim.cmd("setlocal nofoldenable")
            vim.cmd("normal! zR")
        else
            vim.cmd("setlocal foldenable")
            vim.cmd("normal! zM")
        end
    end

    if vim.api.nvim_win_is_valid(current_win) then
        vim.api.nvim_set_current_win(current_win)
    end

    vim.t.review_diff_context_expanded = expanded
end

local function toggle_diff_context_expanded()
    local expanded = not vim.t.review_diff_context_expanded
    set_diff_context_expanded(expanded)
end

local function set_review_diff_state(left_win, right_win, rel_path)
    vim.t.review_diff_left_win = left_win
    vim.t.review_diff_right_win = right_win
    vim.t.review_diff_rel_path = rel_path
    vim.t.review_diff_context_expanded = false
end

local function close_review_diff(opts)
    opts = opts or {}

    local left_win = vim.t.review_diff_left_win
    local right_win = vim.t.review_diff_right_win

    clear_diff_word_highlights()

    if right_win and vim.api.nvim_win_is_valid(right_win) then
        pcall(vim.api.nvim_set_current_win, right_win)
        pcall(vim.cmd, "diffoff")
    elseif vim.wo.diff then
        pcall(vim.cmd, "diffoff")
    end

    if left_win and vim.api.nvim_win_is_valid(left_win) then
        pcall(vim.api.nvim_win_close, left_win, true)
    end

    if right_win and vim.api.nvim_win_is_valid(right_win) then
        pcall(vim.api.nvim_set_current_win, right_win)
        restore_view_in_win(right_win, opts.restore_view)
    end

    clear_review_diff_state()
end

local function open_changed_file(entry, repo_root, opts)
    opts = opts or {}

    if opts.new_tab then
        vim.cmd("tabnew")
    end

    if entry.status_code == "D" then
        return false
    end

    vim.cmd("edit " .. vim.fn.fnameescape(absolute_repo_path(repo_root, entry.path)))
    return true
end

local function open_changed_file_diff(entry, repo_root, base_ref, opts)
    opts = opts or {}

    if opts.new_tab then
        vim.cmd("tabnew")
    else
        close_review_diff()
    end

    local base_lines = load_base_lines(repo_root, entry, base_ref)

    local right_win
    if entry.status_code == "D" then
        vim.cmd("enew")
        local right_buf = vim.api.nvim_get_current_buf()
        configure_scratch_buffer(right_buf, scratch_title("[HEAD deleted]", entry.path), {}, entry.path)
        right_win = vim.api.nvim_get_current_win()
    else
        open_changed_file(entry, repo_root, {})
        right_win = vim.api.nvim_get_current_win()
    end

    vim.cmd("leftabove vnew")
    local left_win = vim.api.nvim_get_current_win()
    local left_buf = vim.api.nvim_get_current_buf()
    configure_scratch_buffer(left_buf, scratch_title("[base origin/" .. base_ref .. "]", entry.base_path), base_lines, entry.base_path)
    vim.cmd("diffthis")

    vim.api.nvim_set_current_win(right_win)
    vim.cmd("diffthis")
    set_review_diff_state(left_win, right_win, entry.path)
    set_diff_context_expanded(true)
end

local function entry_display(entry)
    if entry.status_code == "R" or entry.status_code == "C" then
        return string.format("%-6s %s → %s", entry.status, entry.base_path, entry.path)
    end

    return string.format("%-6s %s", entry.status, entry.path)
end

local function current_buffer_rel_path(repo_root)
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
        return nil
    end

    local absolute = normalize_path(bufname)
    local root = normalize_path(repo_root)
    local prefix = root .. "/"
    if absolute:sub(1, #prefix) ~= prefix then
        return nil
    end

    return absolute:sub(#prefix + 1)
end

local function find_entry_for_rel_path(entries, rel_path)
    for _, entry in ipairs(entries) do
        if entry.path == rel_path then
            return entry
        end
    end

    for _, entry in ipairs(entries) do
        if entry.base_path == rel_path then
            return entry
        end
    end

    return nil
end

local function open_current_buffer_diff(entry, repo_root, base_ref)
    local current_view = save_current_view()
    close_review_diff()

    local base_lines = load_base_lines(repo_root, entry, base_ref)
    local right_win = vim.api.nvim_get_current_win()

    vim.cmd("leftabove vnew")
    local left_win = vim.api.nvim_get_current_win()
    local left_buf = vim.api.nvim_get_current_buf()
    configure_scratch_buffer(left_buf, scratch_title("[base origin/" .. base_ref .. "]", entry.base_path), base_lines, entry.base_path)
    vim.cmd("diffthis")

    vim.api.nvim_set_current_win(right_win)
    vim.cmd("diffthis")
    set_review_diff_state(left_win, right_win, entry.path)
    set_diff_context_expanded(true)
    restore_view_in_win(right_win, current_view)
end

local function toggle_current_file_diff()
    local repo_root = current_repo_root()
    if not repo_root then
        notify("Not inside a git repository", vim.log.levels.WARN)
        return
    end

    local base_ref = resolve_base_ref(repo_root)
    if not base_ref then
        notify("Could not determine a base branch for diffing", vim.log.levels.ERROR)
        return
    end

    local current_rel = current_buffer_rel_path(repo_root)
    local tracked_rel = vim.t.review_diff_rel_path
    local diff_active = (vim.t.review_diff_left_win and vim.api.nvim_win_is_valid(vim.t.review_diff_left_win))
        or (vim.t.review_diff_right_win and vim.api.nvim_win_is_valid(vim.t.review_diff_right_win))
        or vim.wo.diff

    if diff_active and tracked_rel and (current_rel == tracked_rel or current_rel == nil) then
        close_review_diff({ restore_view = save_current_view() })
        return
    end

    if diff_active then
        close_review_diff()
    end

    current_rel = current_buffer_rel_path(repo_root)
    if not current_rel then
        notify("Current buffer is not a file inside this repository", vim.log.levels.WARN)
        return
    end

    local entries, err = changed_files_against_base(repo_root, base_ref)
    if not entries then
        notify(("Failed to list changed files: %s"):format(err), vim.log.levels.ERROR)
        return
    end

    local entry = find_entry_for_rel_path(entries, current_rel) or {
        status = "M",
        status_code = "M",
        base_path = current_rel,
        path = current_rel,
    }

    open_current_buffer_diff(entry, repo_root, base_ref)
end

local function pick_changed_files()
    local repo_root = current_repo_root()
    if not repo_root then
        notify("Not inside a git repository", vim.log.levels.WARN)
        return
    end

    local base_ref, used_default_branch = resolve_base_ref(repo_root)
    if not base_ref then
        notify("Could not determine a base branch for diffing", vim.log.levels.ERROR)
        return
    end

    local entries, err = changed_files_against_base(repo_root, base_ref)
    if not entries then
        notify(("Failed to list changed files: %s"):format(err), vim.log.levels.ERROR)
        return
    end

    if vim.tbl_isempty(entries) then
        notify(("No changed files relative to origin/%s"):format(base_ref))
        return
    end

    if used_default_branch then
        notify(("Using origin/%s as the base branch for changed files"):format(base_ref))
    end

    local ok_picker, pickers = pcall(require, "telescope.pickers")
    local ok_finder, finders = pcall(require, "telescope.finders")
    local ok_conf, conf = pcall(require, "telescope.config")
    local ok_actions, actions = pcall(require, "telescope.actions")
    local ok_state, action_state = pcall(require, "telescope.actions.state")

    if not (ok_picker and ok_finder and ok_conf and ok_actions and ok_state) then
        notify("Telescope is required for changed-files picking", vim.log.levels.ERROR)
        return
    end

    pickers
        .new({}, {
            prompt_title = ("Changed files vs origin/%s (<CR>=open current, <C-d>=diff, <C-t>=new tab)"):format(base_ref),
            finder = finders.new_table({
                results = entries,
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = entry_display(entry),
                        ordinal = table.concat({ entry.status, entry.base_path or "", entry.path or "" }, " "),
                    }
                end,
            }),
            sorter = conf.values.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                local function select(selection_opts)
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if not (selection and selection.value) then
                        return
                    end

                    local entry = selection.value
                    if selection_opts and selection_opts.diff then
                        open_changed_file_diff(entry, repo_root, base_ref, selection_opts)
                        return
                    end

                    local opened = open_changed_file(entry, repo_root, selection_opts)
                    if not opened then
                        notify(("%s is deleted in HEAD; opening a diff view instead"):format(entry.path))
                        open_changed_file_diff(entry, repo_root, base_ref, selection_opts)
                    end
                end

                actions.select_default:replace(function()
                    select({})
                end)

                map("i", "<C-d>", function()
                    select({ diff = true })
                end)
                map("n", "<C-d>", function()
                    select({ diff = true })
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

local function fetch_pull_requests(opts)
    local repo_context = get_repo_context()

    local args = {
        "gh",
        "search",
        "prs",
        "--state",
        "open",
        "--sort",
        "updated",
        "--order",
        "desc",
        "--limit",
        "200",
        "--json",
        "number,title,url,author,repository,updatedAt",
    }

    if opts.review_requested then
        vim.list_extend(args, { "--review-requested", "@me" })
    end

    local scope_label = "algolia/*"
    if repo_context and repo_context.owner_repo then
        vim.list_extend(args, { "--repo", repo_context.owner_repo })
        scope_label = repo_context.owner_repo
    else
        vim.list_extend(args, { "--owner", "algolia" })
    end

    local out, err = run(args)
    if not out then
        notify(("Failed to fetch PRs: %s"):format(err), vim.log.levels.ERROR)
        return nil
    end

    local ok, decoded = pcall(vim.json.decode, out)
    if not ok or type(decoded) ~= "table" then
        notify("Failed to parse PR list from gh output", vim.log.levels.ERROR)
        return nil
    end

    return decoded, scope_label, repo_context
end

local function pad_or_trim(text, width)
    text = text or ""

    local display_width = vim.fn.strdisplaywidth(text)
    if display_width == width then
        return text
    end

    if display_width < width then
        return text .. string.rep(" ", width - display_width)
    end

    if width <= 1 then
        return vim.fn.strcharpart(text, 0, width)
    end

    local shortened = vim.fn.strcharpart(text, 0, width - 1) .. "…"
    local shortened_width = vim.fn.strdisplaywidth(shortened)
    if shortened_width < width then
        shortened = shortened .. string.rep(" ", width - shortened_width)
    end

    return shortened
end

local function build_pr_row_renderer(prs)
    local repo_width = #"repo"
    local number_width = #"pr"
    local author_width = #"author"

    for _, pr in ipairs(prs) do
        local owner_repo = repo_from_pr(pr) or "unknown/repo"
        local author = "@" .. ((pr.author and pr.author.login) or "unknown")
        local pr_number = "#" .. tostring(pr.number)

        repo_width = math.max(repo_width, vim.fn.strdisplaywidth(owner_repo))
        number_width = math.max(number_width, vim.fn.strdisplaywidth(pr_number))
        author_width = math.max(author_width, vim.fn.strdisplaywidth(author))
    end

    repo_width = math.min(repo_width, 32)
    number_width = math.min(math.max(number_width, 6), 10)
    author_width = math.min(author_width, 18)

    local function row(repo_value, pr_value, author_value, updated_value, title_value)
        return table.concat({
            pad_or_trim(repo_value, repo_width),
            pad_or_trim(pr_value, number_width),
            pad_or_trim(author_value, author_width),
            pad_or_trim(updated_value, 10),
            title_value or "",
        }, "  ")
    end

    local results_title = row("repo", "pr", "author", "updated", "title")

    local function render(pr)
        local owner_repo = repo_from_pr(pr) or "unknown/repo"
        local author = "@" .. ((pr.author and pr.author.login) or "unknown")

        return row(owner_repo, "#" .. tostring(pr.number), author, format_iso_date_to_ymd(pr.updatedAt), pr.title or "")
    end

    return render, results_title
end

local function pick_pull_request(opts)
    local prs, scope_label, repo_context = fetch_pull_requests(opts)
    if not prs then
        return
    end

    if vim.tbl_isempty(prs) then
        notify(("No matching PRs found in %s"):format(scope_label))
        return
    end

    local ok_picker, pickers = pcall(require, "telescope.pickers")
    local ok_finder, finders = pcall(require, "telescope.finders")
    local ok_conf, conf = pcall(require, "telescope.config")
    local ok_actions, actions = pcall(require, "telescope.actions")
    local ok_state, action_state = pcall(require, "telescope.actions.state")

    if not (ok_picker and ok_finder and ok_conf and ok_actions and ok_state) then
        notify("Telescope is required for PR picking", vim.log.levels.ERROR)
        return
    end

    local prompt_title = opts.review_requested and ("PRs requesting your review (" .. scope_label .. ")")
        or ("Open PRs (" .. scope_label .. ")")

    local pr_row_renderer, results_title = build_pr_row_renderer(prs)

    pickers
        .new({}, {
            prompt_title = prompt_title,
            results_title = results_title,
            finder = finders.new_table({
                results = prs,
                entry_maker = function(pr)
                    local owner_repo = repo_from_pr(pr) or "unknown/repo"
                    local author = (pr.author and pr.author.login) or "unknown"
                    local updated = format_iso_date_to_ymd(pr.updatedAt)

                    local fallback_display = ("%s #%d @%s %s %s"):format(
                        owner_repo,
                        pr.number,
                        author,
                        updated,
                        pr.title or ""
                    )

                    return {
                        value = pr,
                        display = pr_row_renderer and pr_row_renderer(pr) or fallback_display,
                        ordinal = table.concat({
                            owner_repo,
                            tostring(pr.number),
                            author,
                            updated,
                            pr.title or "",
                            pr.url or "",
                        }, " "),
                    }
                end,
            }),
            sorter = conf.values.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
                local function select_pr()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if selection and selection.value then
                        checkout_and_open_diff(selection.value, repo_context)
                    end
                end

                actions.select_default:replace(select_pr)
                return true
            end,
        })
        :find()
end

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

vim.keymap.set("n", "<leader>gc", function()
    pick_changed_files()
end, { desc = "Pick changed files against PR/default base" })

vim.keymap.set("n", "<leader>gd", function()
    toggle_current_file_diff()
end, { desc = "Toggle current file diff against PR/default base" })

vim.keymap.set("n", "<leader>ge", function()
    toggle_diff_context_expanded()
end, { desc = "Toggle expanded context in diff windows" })

vim.keymap.set("n", "<leader>gr", function()
    pick_pull_request({ review_requested = true })
end, { desc = "Review-requested PRs (repo if inside one, else algolia)" })

vim.keymap.set("n", "<leader>gR", function()
    pick_pull_request({ review_requested = false })
end, { desc = "Open PRs (repo if inside one, else algolia)" })

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "CursorHold", "CursorHoldI", "WinEnter", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("review-diff-word-highlight", { clear = true }),
    callback = function()
        if vim.wo.diff then
            update_diff_word_highlights()
        else
            clear_diff_word_highlights()
        end
    end,
})
