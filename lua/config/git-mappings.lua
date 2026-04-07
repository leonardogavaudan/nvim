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

local function ensure_local_repo(owner_repo, repo_context)
    if repo_context and repo_context.owner_repo == owner_repo then
        return repo_context.git_root
    end

    local repo_name = owner_repo:match("/([^/]+)$")
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

    local _, checkout_err = run(
        { "gh", "pr", "checkout", tostring(pr.number), "--repo", owner_repo },
        { cwd = repo_path }
    )
    if checkout_err then
        notify(("Failed to checkout %s#%d: %s"):format(owner_repo, pr.number, checkout_err), vim.log.levels.ERROR)
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

    run({ "git", "fetch", "origin", base_ref }, { cwd = repo_path })

    vim.cmd("cd " .. vim.fn.fnameescape(repo_path))
    pcall(vim.cmd, "DiffviewClose")

    local ok, err = pcall(vim.cmd, "DiffviewOpen origin/" .. base_ref .. "...HEAD")
    if not ok then
        notify(("Failed to open Diffview: %s"):format(err), vim.log.levels.ERROR)
        open_url(pr.url)
        return
    end

    notify(("Reviewing %s#%d (base: %s)"):format(owner_repo, pr.number, base_ref))
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

vim.keymap.set("n", "<leader>gr", function()
    pick_pull_request({ review_requested = true })
end, { desc = "Review-requested PRs (repo if inside one, else algolia)" })

vim.keymap.set("n", "<leader>gR", function()
    pick_pull_request({ review_requested = false })
end, { desc = "Open PRs (repo if inside one, else algolia)" })
