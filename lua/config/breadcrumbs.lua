local M = {}

local preview_ns = vim.api.nvim_create_namespace("lg-breadcrumbs-preview")
local menu_ns = vim.api.nvim_create_namespace("lg-breadcrumbs-menu")
local menu_selection_ns = vim.api.nvim_create_namespace("lg-breadcrumbs-menu-selection")
local augroup = vim.api.nvim_create_augroup("lg-breadcrumbs", { clear = true })

local defaults = {
    excluded_buftypes = {
        "help",
        "nofile",
        "prompt",
        "quickfix",
        "terminal",
    },
    excluded_filetypes = {
        "DiffviewFiles",
        "TelescopePrompt",
        "gitcommit",
        "help",
        "lazy",
        "mason",
        "oil",
        "qf",
    },
    max_menu_height = 12,
    max_menu_width = 60,
    menu_winblend = 0,
    preview_row_fraction = 0.33,
    refresh_debounce_ms = 150,
}

local kind_icons = {
    [1] = "󰈙", -- File
    [2] = "󰏗", -- Module
    [3] = "󰌗", -- Namespace
    [4] = "󰏗", -- Package
    [5] = "󰠱", -- Class
    [6] = "", -- Method
    [7] = "", -- Property
    [8] = "", -- Field
    [9] = "", -- Constructor
    [10] = "", -- Enum
    [11] = "", -- Interface
    [12] = "󰊕", -- Function
    [13] = "", -- Variable
    [14] = "󰏿", -- Constant
    [15] = "", -- String
    [16] = "󰎠", -- Number
    [17] = "◩", -- Boolean
    [18] = "󰅪", -- Array
    [19] = "󰅩", -- Object
    [20] = "󰌋", -- Key
    [21] = "󰟢", -- Null
    [22] = "", -- EnumMember
    [23] = "󰜢", -- Struct
    [24] = "", -- Event
    [25] = "󰆕", -- Operator
    [26] = "󰊄", -- TypeParameter
}

M.config = vim.deepcopy(defaults)
M.state = {
    cache = {},
    pending = {},
    refresh_seq = {},
    menu = nil,
    enabled = true,
}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Breadcrumbs" })
end

local function get_buf_changedtick(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return -1
    end

    return vim.api.nvim_buf_get_changedtick(bufnr)
end

local function is_float(winid)
    if not vim.api.nvim_win_is_valid(winid) then
        return false
    end

    return vim.api.nvim_win_get_config(winid).relative ~= ""
end

local function is_supported_buffer(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    if vim.tbl_contains(M.config.excluded_buftypes, vim.bo[bufnr].buftype) then
        return false
    end

    if vim.tbl_contains(M.config.excluded_filetypes, vim.bo[bufnr].filetype) then
        return false
    end

    return true
end

local function is_supported_window(winid)
    if not vim.api.nvim_win_is_valid(winid) then
        return false
    end

    if is_float(winid) then
        return false
    end

    return is_supported_buffer(vim.api.nvim_win_get_buf(winid))
end

local function escape_statusline(text)
    return (text or ""):gsub("%%", "%%%%")
end

local function display_width(text)
    return vim.fn.strdisplaywidth(text or "")
end

local function file_label(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        return "[No Name]"
    end

    return vim.fn.fnamemodify(name, ":t")
end

local function set_highlights()
    vim.api.nvim_set_hl(0, "BreadcrumbsDim", { link = "Comment" })
    vim.api.nvim_set_hl(0, "BreadcrumbsActive", { link = "Identifier" })
    vim.api.nvim_set_hl(0, "BreadcrumbsPreview", { link = "Visual" })
    vim.api.nvim_set_hl(0, "BreadcrumbsMenuIcon", { link = "Special" })
    vim.api.nvim_set_hl(0, "BreadcrumbsMenuChevron", { link = "Comment" })
    vim.api.nvim_set_hl(0, "BreadcrumbsMenuTitle", { link = "Comment" })
    vim.api.nvim_set_hl(0, "BreadcrumbsMenuCursorLine", { link = "PmenuSel" })
    vim.api.nvim_set_hl(0, "BreadcrumbsMenuSelection", { link = "PmenuSel" })
end

local function buffer_windows(bufnr)
    local windows = {}

    for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
        if vim.api.nvim_win_is_valid(winid) and not is_float(winid) then
            windows[#windows + 1] = winid
        end
    end

    return windows
end

local function clear_managed_winbar(winid)
    if not vim.api.nvim_win_is_valid(winid) then
        return
    end

    if vim.w[winid].lg_breadcrumbs_managed then
        vim.wo[winid].winbar = vim.w[winid].lg_breadcrumbs_previous_winbar or ""
        vim.w[winid].lg_breadcrumbs_previous_winbar = nil
        vim.w[winid].lg_breadcrumbs_managed = false
    end
end

local function set_managed_winbar(winid, value)
    if not vim.api.nvim_win_is_valid(winid) then
        return
    end

    if not vim.w[winid].lg_breadcrumbs_managed then
        vim.w[winid].lg_breadcrumbs_previous_winbar = vim.wo[winid].winbar
    end

    vim.wo[winid].winbar = value
    vim.w[winid].lg_breadcrumbs_managed = true
end

local function clear_preview(bufnr)
    if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_clear_namespace(bufnr, preview_ns, 0, -1)
    end
end

local function valid_range(range)
    if type(range) ~= "table" or type(range.start) ~= "table" or type(range["end"]) ~= "table" then
        return false
    end

    local start_pos = range.start
    local end_pos = range["end"]

    if start_pos.line > end_pos.line then
        return false
    end

    if start_pos.line == end_pos.line and start_pos.character > end_pos.character then
        return false
    end

    return true
end

local function highlight_range(bufnr, range)
    clear_preview(bufnr)

    if not vim.api.nvim_buf_is_valid(bufnr) or not valid_range(range) then
        return
    end

    pcall(vim.api.nvim_buf_set_extmark, bufnr, preview_ns, range.start.line, range.start.character, {
        end_row = range["end"].line,
        end_col = range["end"].character,
        hl_group = "BreadcrumbsPreview",
        hl_eol = true,
        priority = 200,
    })
end

local function symbol_sort_key(symbol)
    local range = symbol.selectionRange or symbol.range or {}
    local start_pos = range.start or {}
    return start_pos.line or math.huge, start_pos.character or math.huge
end

local function sort_symbols_in_source_order(symbols)
    table.sort(symbols, function(a, b)
        local a_line, a_col = symbol_sort_key(a)
        local b_line, b_col = symbol_sort_key(b)

        if a_line ~= b_line then
            return a_line < b_line
        end

        if a_col ~= b_col then
            return a_col < b_col
        end

        return (a.name or "") < (b.name or "")
    end)

    return symbols
end

local function normalize_document_symbols(symbols, parent)
    local normalized = {}

    for _, symbol in ipairs(symbols or {}) do
        local node = {
            name = symbol.name or "[Anonymous]",
            kind = symbol.kind,
            range = symbol.range,
            selectionRange = symbol.selectionRange or symbol.range,
            parent = parent,
            children = {},
        }

        node.children = normalize_document_symbols(symbol.children or {}, node)
        table.insert(normalized, node)
    end

    return sort_symbols_in_source_order(normalized)
end

local function normalize_symbol_information(symbols)
    local normalized = {}

    for _, symbol in ipairs(symbols or {}) do
        local range = symbol.location and symbol.location.range or symbol.range
        table.insert(normalized, {
            name = symbol.name or "[Anonymous]",
            kind = symbol.kind,
            range = range,
            selectionRange = range,
            parent = nil,
            children = {},
        })
    end

    return sort_symbols_in_source_order(normalized)
end

local function normalize_symbols(result)
    if type(result) ~= "table" or vim.tbl_isempty(result) then
        return {}
    end

    local first = result[1]
    if type(first) ~= "table" then
        return {}
    end

    if first.location then
        return normalize_symbol_information(result)
    end

    return normalize_document_symbols(result, nil)
end

local function score_symbols(symbols)
    local count = 0
    local max_depth = 0

    local function walk(nodes, depth)
        max_depth = math.max(max_depth, depth)
        for _, node in ipairs(nodes) do
            count = count + 1
            walk(node.children, depth + 1)
        end
    end

    walk(symbols or {}, 1)

    return (count * 100) + max_depth
end

local request_symbols

local function finish_request(bufnr, symbols, changedtick)
    local pending = M.state.pending[bufnr]
    M.state.pending[bufnr] = nil

    M.state.cache[bufnr] = {
        changedtick = changedtick,
        symbols = symbols or {},
    }

    if pending then
        for _, callback in ipairs(pending.callbacks) do
            pcall(callback, symbols or {})
        end
    end
end

local function schedule_refresh(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    M.state.refresh_seq[bufnr] = (M.state.refresh_seq[bufnr] or 0) + 1
    local seq = M.state.refresh_seq[bufnr]

    vim.defer_fn(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        if M.state.refresh_seq[bufnr] ~= seq then
            return
        end

        request_symbols(bufnr, { force = true })

        for _, winid in ipairs(buffer_windows(bufnr)) do
            M.update_winbar(winid)
        end
    end, M.config.refresh_debounce_ms)
end

request_symbols = function(bufnr, opts)
    opts = opts or {}

    if not is_supported_buffer(bufnr) then
        if opts.on_complete then
            opts.on_complete({})
        end
        return
    end

    local changedtick = get_buf_changedtick(bufnr)
    local cache = M.state.cache[bufnr]
    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/documentSymbol" })
    local has_symbol_clients = not vim.tbl_isempty(clients)

    if not opts.force and cache and cache.changedtick == changedtick then
        local cached_symbols = cache.symbols or {}
        if not has_symbol_clients or not vim.tbl_isempty(cached_symbols) then
            if opts.on_complete then
                opts.on_complete(cached_symbols)
            end
            return
        end
    end

    local pending = M.state.pending[bufnr]
    if pending then
        if opts.on_complete then
            table.insert(pending.callbacks, opts.on_complete)
        end
        return
    end

    if not has_symbol_clients then
        finish_request(bufnr, {}, changedtick)
        if opts.on_complete then
            opts.on_complete({})
        end
        return
    end

    pending = {
        callbacks = {},
        changedtick = changedtick,
    }
    if opts.on_complete then
        table.insert(pending.callbacks, opts.on_complete)
    end
    M.state.pending[bufnr] = pending

    local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
    vim.lsp.buf_request_all(bufnr, "textDocument/documentSymbol", params, function(results)
        local best_symbols = {}
        local best_score = -1

        for _, response in pairs(results or {}) do
            if response and not response.error and response.result then
                local normalized = normalize_symbols(response.result)
                local score = score_symbols(normalized)
                if score > best_score then
                    best_score = score
                    best_symbols = normalized
                end
            end
        end

        finish_request(bufnr, best_symbols, changedtick)

        for _, winid in ipairs(buffer_windows(bufnr)) do
            vim.schedule(function()
                if vim.api.nvim_win_is_valid(winid) then
                    M.update_winbar(winid)
                end
            end)
        end

        if get_buf_changedtick(bufnr) ~= changedtick then
            schedule_refresh(bufnr)
        end
    end)
end

local function contains(range, row, col)
    if not valid_range(range) then
        return false
    end

    local start_pos = range.start
    local end_pos = range["end"]

    if row < start_pos.line or row > end_pos.line then
        return false
    end

    if row == start_pos.line and col < start_pos.character then
        return false
    end

    if row == end_pos.line and col >= end_pos.character then
        return false
    end

    return true
end

local function find_deepest_symbol(symbols, row, col)
    local best

    local function walk(nodes)
        for _, node in ipairs(nodes or {}) do
            if contains(node.range, row, col) then
                best = node
                walk(node.children)
            end
        end
    end

    walk(symbols)

    return best
end

local function path_for_window(winid, symbols)
    if not vim.api.nvim_win_is_valid(winid) then
        return {}
    end

    local cursor = vim.api.nvim_win_get_cursor(winid)
    local row = cursor[1] - 1
    local col = cursor[2]

    local node = find_deepest_symbol(symbols, row, col)
    local path = {}

    while node do
        table.insert(path, 1, node)
        node = node.parent
    end

    return path
end

local function index_of(nodes, needle)
    if not needle then
        return nil
    end

    for index, node in ipairs(nodes or {}) do
        if node == needle then
            return index
        end
    end

    return nil
end

local function current_symbols(bufnr)
    local cache = M.state.cache[bufnr]
    if not cache then
        return {}
    end

    return cache.symbols or {}
end

local function render_winbar(winid)
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local symbols = current_symbols(bufnr)
    if vim.tbl_isempty(symbols) and not M.state.pending[bufnr] then
        request_symbols(bufnr)
    end

    local path = path_for_window(winid, symbols)
    local parts = {
        "%<",
        "%#WinBar#",
        "%0@v:lua.__lg_breadcrumbs_click@",
        escape_statusline(file_label(bufnr)),
        "%T",
    }

    for index, node in ipairs(path) do
        parts[#parts + 1] = "%#BreadcrumbsDim# › "
        parts[#parts + 1] = ("%%%d@v:lua.__lg_breadcrumbs_click@"):format(index)
        parts[#parts + 1] = index == #path and "%#BreadcrumbsActive#" or "%#WinBar#"
        parts[#parts + 1] = escape_statusline(node.name)
        parts[#parts + 1] = "%T"
    end

    return table.concat(parts)
end

function M.update_winbar(winid)
    if not M.state.enabled then
        if winid and vim.api.nvim_win_is_valid(winid) then
            clear_managed_winbar(winid)
        end
        return
    end

    winid = winid or vim.api.nvim_get_current_win()
    if not is_supported_window(winid) then
        clear_managed_winbar(winid)
        return
    end

    local winbar = render_winbar(winid)
    set_managed_winbar(winid, winbar)
end

local function preview_position(symbol)
    local target = symbol.selectionRange or symbol.range
    if not valid_range(target) then
        return nil
    end

    return {
        line = target.start.line + 1,
        col = target.start.character,
    }
end

local function preview_symbol(symbol)
    local menu = M.state.menu
    if not menu or not symbol then
        return
    end

    if not vim.api.nvim_win_is_valid(menu.source_win) or not vim.api.nvim_buf_is_valid(menu.source_buf) then
        return
    end

    local pos = preview_position(symbol)
    if pos then
        vim.api.nvim_win_call(menu.source_win, function()
            pcall(vim.api.nvim_win_set_cursor, menu.source_win, { pos.line, pos.col })
            pcall(vim.cmd, "normal! zv")

            local height = vim.api.nvim_win_get_height(menu.source_win)
            local target_row = math.max(1, math.floor(height * M.config.preview_row_fraction))
            local view = vim.fn.winsaveview()
            view.topline = math.max(1, pos.line - target_row + 1)
            pcall(vim.fn.winrestview, view)
        end)
    end

    highlight_range(menu.source_buf, symbol.range)
    M.update_winbar(menu.source_win)
end

local function menu_title(_)
    return nil
end

local function make_menu_win_config(config)
    local win_config = {
        relative = "editor",
        row = config.row,
        col = config.col,
        width = config.width,
        height = config.height,
        style = "minimal",
        border = "single",
        zindex = 150,
    }

    if config.title and config.title ~= "" then
        win_config.title = config.title
        win_config.title_pos = "left"
    end

    return win_config
end

local function item_index_of(items, needle_node)
    if not needle_node then
        return nil
    end

    for index, item in ipairs(items or {}) do
        if item.node == needle_node then
            return index
        end
    end

    return nil
end

local function collect_menu_entries(menu, nodes, depth, out)
    for _, node in ipairs(nodes or {}) do
        local has_children = not vim.tbl_isempty(node.children)
        local expanded = has_children and menu.expanded[node] or false
        out[#out + 1] = {
            node = node,
            depth = depth,
            expanded = expanded,
            has_children = has_children,
        }

        if expanded then
            collect_menu_entries(menu, node.children, depth + 1, out)
        end
    end
end

local function render_entry(item)
    local icon = kind_icons[item.node.kind] or "󰈔"
    local indent = string.rep("  ", item.depth)
    local chevron = item.has_children and (item.expanded and "▾" or "▸") or " "
    local line = (" %s%s %s  %s "):format(indent, chevron, icon, item.node.name)
    local chevron_start = 1 + #indent
    local chevron_end = chevron_start + #chevron
    local icon_start = chevron_end + 1
    local icon_end = icon_start + #icon

    return {
        line = line,
        chevron_start = chevron_start,
        chevron_end = chevron_end,
        icon_start = icon_start,
        icon_end = icon_end,
    }
end

local function apply_menu_highlights(bufnr, rendered)
    vim.api.nvim_buf_clear_namespace(bufnr, menu_ns, 0, -1)

    for index, item in ipairs(rendered) do
        vim.api.nvim_buf_add_highlight(
            bufnr,
            menu_ns,
            "BreadcrumbsMenuChevron",
            index - 1,
            item.chevron_start,
            item.chevron_end
        )
        vim.api.nvim_buf_add_highlight(bufnr, menu_ns, "BreadcrumbsMenuIcon", index - 1, item.icon_start, item.icon_end)
    end
end

local function update_menu_selection_highlight(menu)
    if not menu or not vim.api.nvim_buf_is_valid(menu.buf) then
        return
    end

    vim.api.nvim_buf_clear_namespace(menu.buf, menu_selection_ns, 0, -1)

    if not menu.entries[menu.selected_idx] then
        return
    end

    vim.api.nvim_buf_set_extmark(menu.buf, menu_selection_ns, menu.selected_idx - 1, 0, {
        line_hl_group = "BreadcrumbsMenuSelection",
        priority = 200,
    })
end

local function sync_selection_from_cursor()
    local menu = M.state.menu
    if not menu or not vim.api.nvim_win_is_valid(menu.win) then
        return
    end

    local line = vim.api.nvim_win_get_cursor(menu.win)[1]
    line = math.max(1, math.min(line, #menu.entries))

    if menu.selected_idx == line then
        return
    end

    menu.selected_idx = line
    update_menu_selection_highlight(menu)
    local selected = menu.entries[menu.selected_idx]
    if selected then
        preview_symbol(selected.node)
    end
end

local function set_scope(scope_parent, focus_node)
    local menu = M.state.menu
    if not menu then
        return
    end

    local base_entries = scope_parent and scope_parent.children or menu.roots
    if vim.tbl_isempty(base_entries) then
        return
    end

    menu.scope_parent = scope_parent
    menu.base_entries = base_entries
    menu.expanded = menu.expanded or {}

    local entries = {}
    collect_menu_entries(menu, base_entries, 0, entries)
    menu.entries = entries
    menu.selected_idx = item_index_of(entries, focus_node) or math.min(menu.selected_idx or 1, #entries)
    menu.selected_idx = math.max(1, menu.selected_idx)

    local rendered = {}
    local lines = {}
    local max_width = 0
    for _, entry in ipairs(entries) do
        local item = render_entry(entry)
        rendered[#rendered + 1] = item
        lines[#lines + 1] = item.line
        max_width = math.max(max_width, display_width(item.line))
    end

    vim.bo[menu.buf].modifiable = true
    vim.api.nvim_buf_set_lines(menu.buf, 0, -1, false, lines)
    vim.bo[menu.buf].modifiable = false
    apply_menu_highlights(menu.buf, rendered)

    local title = menu_title(menu)
    local source_width = vim.api.nvim_win_is_valid(menu.source_win) and vim.api.nvim_win_get_width(menu.source_win)
        or M.config.max_menu_width
    local width = math.min(
        math.max(max_width, title and (display_width(title) + 2) or 0, 24),
        math.max(24, source_width - 2),
        M.config.max_menu_width
    )
    local height = math.min(#entries, M.config.max_menu_height)
    local anchor = menu.anchor
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines - vim.o.cmdheight
    local col = math.max(0, math.min(anchor.col, math.max(0, editor_width - width - 2)))
    local row = math.max(0, math.min(anchor.row, math.max(0, editor_height - height - 2)))

    vim.api.nvim_win_set_config(
        menu.win,
        make_menu_win_config({
            row = row,
            col = col,
            width = width,
            height = height,
            title = title,
        })
    )

    vim.api.nvim_win_set_cursor(menu.win, { menu.selected_idx, 0 })
    update_menu_selection_highlight(menu)
    local selected = menu.entries[menu.selected_idx]
    if selected then
        preview_symbol(selected.node)
    end
end

local function default_anchor(winid)
    local pos = vim.api.nvim_win_get_position(winid)
    local wininfo = vim.fn.getwininfo(winid)[1] or {}
    local textoff = wininfo.textoff or 0

    return {
        row = pos[1] + 1,
        col = pos[2] + textoff,
    }
end

local function anchor_for_segment(winid, segment_index, path)
    local anchor = default_anchor(winid)
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local prefix_width = 0

    if segment_index and segment_index > 0 then
        prefix_width = display_width(file_label(bufnr))

        for index = 1, segment_index do
            prefix_width = prefix_width + display_width(" › ")
            if index < segment_index and path[index] then
                prefix_width = prefix_width + display_width(path[index].name)
            end
        end
    end

    anchor.col = anchor.col + prefix_width

    return anchor
end

local function create_menu_buffer()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buflisted = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "breadcrumbs-menu"
    vim.bo[buf].swapfile = false
    return buf
end

local function close_menu(confirm)
    local menu = M.state.menu
    if not menu then
        return
    end

    menu.closing = true

    if not confirm and vim.api.nvim_win_is_valid(menu.source_win) then
        vim.api.nvim_win_call(menu.source_win, function()
            pcall(vim.fn.winrestview, menu.original_view)
        end)
    end

    clear_preview(menu.source_buf)

    if vim.api.nvim_win_is_valid(menu.win) then
        pcall(vim.api.nvim_win_close, menu.win, true)
    end

    M.state.menu = nil

    if vim.api.nvim_win_is_valid(menu.source_win) then
        pcall(vim.api.nvim_set_current_win, menu.source_win)
        M.update_winbar(menu.source_win)
    end
end

local function confirm_selection()
    close_menu(true)
end

local function select_menu_index(index)
    local menu = M.state.menu
    if not menu or not menu.entries[index] then
        return
    end

    menu.selected_idx = index
    vim.api.nvim_win_set_cursor(menu.win, { index, 0 })
    update_menu_selection_highlight(menu)
    preview_symbol(menu.entries[index].node)
end

local function scope_up()
    local menu = M.state.menu
    if not menu then
        return
    end

    local item = menu.entries[menu.selected_idx]
    if not item then
        return
    end

    if item.has_children and menu.expanded[item.node] then
        menu.expanded[item.node] = nil
        set_scope(menu.scope_parent, item.node)
        return
    end

    if item.depth == 0 then
        return
    end

    for index = menu.selected_idx - 1, 1, -1 do
        if menu.entries[index].depth < item.depth then
            select_menu_index(index)
            return
        end
    end
end

local function scope_down()
    local menu = M.state.menu
    if not menu then
        return
    end

    local item = menu.entries[menu.selected_idx]
    if not item or not item.has_children then
        return
    end

    if not menu.expanded[item.node] then
        menu.expanded[item.node] = true
        set_scope(menu.scope_parent, item.node)
        return
    end

    local next_item = menu.entries[menu.selected_idx + 1]
    if next_item and next_item.depth > item.depth then
        select_menu_index(menu.selected_idx + 1)
    end
end

local function seed_scope(roots, seed_node, root_focus)
    if not seed_node then
        return nil, root_focus or roots[1]
    end

    return seed_node.parent, seed_node
end

local function open_menu_with_symbols(opts)
    if M.state.menu then
        close_menu(false)
    end

    local winid = opts.winid
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local roots = opts.symbols
    if vim.tbl_isempty(roots) then
        notify("No document symbols available for this buffer", vim.log.levels.WARN)
        return
    end

    local buf = create_menu_buffer()
    local anchor = opts.anchor or default_anchor(winid)
    local scope_parent, focus_node = seed_scope(roots, opts.seed_node, opts.root_focus)
    local menu_win = vim.api.nvim_open_win(
        buf,
        true,
        make_menu_win_config({
            row = anchor.row,
            col = anchor.col,
            width = 20,
            height = 1,
            title = menu_title({ scope_parent = scope_parent, source_buf = bufnr }),
        })
    )

    vim.wo[menu_win].cursorline = true
    vim.wo[menu_win].cursorlineopt = "line"
    vim.wo[menu_win].number = false
    vim.wo[menu_win].relativenumber = false
    vim.wo[menu_win].signcolumn = "no"
    vim.wo[menu_win].spell = false
    vim.wo[menu_win].wrap = false
    vim.wo[menu_win].list = false
    vim.wo[menu_win].winblend = M.config.menu_winblend
    vim.wo[menu_win].winhl = table.concat({
        "Normal:Pmenu",
        "FloatBorder:FloatBorder",
        "FloatTitle:BreadcrumbsMenuTitle",
        "CursorLine:BreadcrumbsMenuCursorLine",
    }, ",")

    M.state.menu = {
        anchor = anchor,
        base_entries = {},
        buf = buf,
        entries = {},
        expanded = {},
        original_view = vim.fn.winsaveview(),
        roots = roots,
        scope_parent = nil,
        selected_idx = 1,
        source_buf = bufnr,
        source_win = winid,
        win = menu_win,
    }

    local menu_group = vim.api.nvim_create_augroup(("lg-breadcrumbs-menu-%d"):format(buf), { clear = true })
    vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = buf,
        group = menu_group,
        callback = sync_selection_from_cursor,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        group = menu_group,
        once = true,
        callback = function()
            if M.state.menu and M.state.menu.buf == buf and not M.state.menu.closing then
                local source_buf = M.state.menu.source_buf
                local source_win = M.state.menu.source_win
                local original_view = M.state.menu.original_view
                M.state.menu = nil
                clear_preview(source_buf)
                if vim.api.nvim_win_is_valid(source_win) then
                    vim.api.nvim_win_call(source_win, function()
                        pcall(vim.fn.winrestview, original_view)
                    end)
                    M.update_winbar(source_win)
                end
            end
        end,
    })
    vim.api.nvim_create_autocmd("WinClosed", {
        group = menu_group,
        pattern = tostring(winid),
        once = true,
        callback = function()
            if M.state.menu and M.state.menu.buf == buf then
                close_menu(true)
            end
        end,
    })

    local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc, nowait = true, silent = true })
    end

    map("<CR>", confirm_selection, "Jump to selected symbol")
    map("<Esc>", function()
        close_menu(false)
    end, "Close breadcrumbs menu")
    map("q", function()
        close_menu(false)
    end, "Close breadcrumbs menu")
    map("h", scope_up, "Move to parent scope")
    map("<BS>", scope_up, "Move to parent scope")
    map("<Left>", scope_up, "Move to parent scope")
    map("l", scope_down, "Move to child scope")
    map("<Right>", scope_down, "Move to child scope")

    set_scope(scope_parent, focus_node)
end

local function open_with_resolved_symbols(opts)
    local winid = opts.winid or vim.api.nvim_get_current_win()
    if not is_supported_window(winid) then
        notify("Breadcrumbs are only available in regular file windows", vim.log.levels.WARN)
        return
    end

    local bufnr = vim.api.nvim_win_get_buf(winid)
    request_symbols(bufnr, {
        force = opts.force,
        on_complete = function(symbols)
            if not vim.api.nvim_win_is_valid(winid) then
                return
            end

            local current_path = path_for_window(winid, symbols)
            local seed_node = opts.seed_node
            local root_focus = opts.root_focus

            if opts.segment_index == 0 then
                root_focus = current_path[1]
                seed_node = nil
            elseif opts.segment_index and current_path[opts.segment_index] then
                seed_node = current_path[opts.segment_index]
            elseif seed_node == nil then
                seed_node = current_path[#current_path]
                root_focus = current_path[1]
            end

            local segment_index = opts.segment_index
            if segment_index == nil and seed_node then
                segment_index = index_of(current_path, seed_node)
            end

            open_menu_with_symbols({
                anchor = opts.anchor or anchor_for_segment(winid, segment_index or 0, current_path),
                root_focus = root_focus,
                seed_node = seed_node,
                symbols = symbols,
                winid = winid,
            })
        end,
    })
end

function M.open_menu(winid)
    open_with_resolved_symbols({ winid = winid })
end

function M.refresh(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    request_symbols(bufnr, { force = true })
    for _, winid in ipairs(buffer_windows(bufnr)) do
        M.update_winbar(winid)
    end
end

function M.toggle()
    M.state.enabled = not M.state.enabled

    if not M.state.enabled then
        close_menu(false)
        for _, winid in ipairs(vim.api.nvim_list_wins()) do
            clear_managed_winbar(winid)
        end
        notify("Breadcrumbs disabled")
        return
    end

    notify("Breadcrumbs enabled")
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        M.update_winbar(winid)
    end
end

function M._click(minwid, _, button)
    if button ~= "l" then
        return
    end

    local mouse = vim.fn.getmousepos()
    local winid = mouse.winid
    if not is_supported_window(winid) then
        return
    end

    local anchor = {
        row = math.max(0, (mouse.screenrow or 1) - 1),
        col = math.max(0, (mouse.screencol or 1) - 1),
    }

    vim.schedule(function()
        open_with_resolved_symbols({
            anchor = anchor,
            segment_index = minwid,
            winid = winid,
        })
    end)
end

function M.setup(opts)
    if M._setup_done then
        if opts then
            M.config = vim.tbl_deep_extend("force", M.config, opts)
        end
        return
    end

    M._setup_done = true
    M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

    set_highlights()
    _G.__lg_breadcrumbs_click = M._click

    vim.api.nvim_create_user_command("BreadcrumbsMenu", function()
        M.open_menu()
    end, { desc = "Open breadcrumbs symbol menu" })

    vim.api.nvim_create_user_command("BreadcrumbsRefresh", function()
        M.refresh()
    end, { desc = "Refresh breadcrumbs document symbols" })

    vim.api.nvim_create_user_command("BreadcrumbsToggle", function()
        M.toggle()
    end, { desc = "Toggle breadcrumbs winbar" })

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = augroup,
        callback = set_highlights,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "LspAttach", "WinEnter" }, {
        group = augroup,
        callback = function(args)
            local winid = vim.api.nvim_get_current_win()
            if vim.api.nvim_win_get_buf(winid) == args.buf then
                M.update_winbar(winid)
            end

            request_symbols(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
        group = augroup,
        callback = function()
            M.update_winbar(vim.api.nvim_get_current_win())
        end,
    })

    vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "BufWritePost" }, {
        group = augroup,
        callback = function(args)
            schedule_refresh(args.buf)
            local winid = vim.api.nvim_get_current_win()
            if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == args.buf then
                M.update_winbar(winid)
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = augroup,
        callback = function(args)
            M.state.cache[args.buf] = nil
            M.state.pending[args.buf] = nil
            M.state.refresh_seq[args.buf] = nil
            clear_preview(args.buf)
        end,
    })
end

return M
