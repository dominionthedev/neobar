-- Neobar window + rendering.
--
-- Container: plain vim.api.nvim_open_win, not nui.split. edgy.nvim
-- (the docking layer) works on ANY window whose buffer matches a
-- configured filetype — confirmed from edgy's own README, it doesn't
-- care how the window was created. Since nui.split's value-add over
-- raw nvim_open_win is convenience we don't need for something this
-- simple, going straight to the API gives direct control over exactly
-- what edgy needs to detect (filetype) without an extra layer.
--
-- Rendering: nui.line / nui.text, confirmed by reading their actual
-- source (lua/nui/line/init.lua, lua/nui/text/init.lua) rather than
-- just the README — Line:append(content, highlight) and
-- Line:render(bufnr, ns_id, linenr_start) do real work (buf_set_lines
-- + highlight in one call), which is a genuine improvement over
-- hand-rolling nvim_buf_add_highlight per row.

local NuiLine = require("nui.line")
local neobar = require("neobar")
local icons = require("neobar.icons")

local M = {}

local FILETYPE = "neobar"
local NS = vim.api.nvim_create_namespace("neobar")

-- Highlight groups, linked (not hardcoded hex) so they automatically
-- follow whatever colorscheme/flavour is active.
--
-- This was the real bug behind "there's no opened/closed behaviour":
-- render() below always referenced "NeobarIcon"/"NeobarIconActive",
-- but nothing ever defined them anywhere. An undefined highlight name
-- isn't an error in Neovim — it just silently renders as the default
-- Normal color, so the active/inactive distinction was being computed
-- correctly the whole time, it just had no visual representation.
local function define_highlights()
    -- Inactive: readable muted, not Comment-dim.
    -- Active: bright + bold, plus a left accent bar (NeobarIndicator).
    vim.api.nvim_set_hl(0, "NeobarIcon", { link = "NonText", default = true })
    vim.api.nvim_set_hl(0, "NeobarIconActive", { link = "Title", default = true, bold = true })
    vim.api.nvim_set_hl(0, "NeobarIndicator", { link = "DiagnosticInfo", default = true })
    vim.api.nvim_set_hl(0, "NeobarBg", { link = "NormalFloat", default = true })
end

-- Only rows for adapters that actually exist get rendered — icons.lua
-- lists all seven planned slots, but explorer/git/plugins are the only
-- ones with a real adapter so far. Rendering a row for an adapter that
-- doesn't exist yet would mean every click silently does nothing,
-- which is worse than just not showing it.
local function active_icons()
    local out = {}
    for _, entry in ipairs(icons) do
        if neobar.get(entry.adapter) then
            table.insert(out, entry)
        end
    end
    return out
end

M.buf = nil
M.win = nil

-- linenr (1-indexed) -> adapter name for the current render layout.
-- Blank gap/pad lines are absent from this map so clicks on them no-op.
local line_map = {}

-- Last known is_open() snapshot keyed by adapter name. Used by the
-- refresh path so we only re-render when something actually changed.
local last_active = {}

-- Augroup + timer for event-driven / periodic refresh. Created on
-- first open, cleared when the window goes away.
local refresh_augroup = nil
local refresh_timer = nil
local REFRESH_INTERVAL_MS = 1000 -- soft fallback poll; events do the real work
local refresh_pending = false

local function ensure_buf()
    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
        return M.buf
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = FILETYPE
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = false

    M.buf = buf
    return buf
end

--- Snapshot of current is_open() for every registered adapter.
---@return table<string, boolean>
local function snapshot_active()
    local snap = {}
    for _, entry in ipairs(active_icons()) do
        local adapter = neobar.get(entry.adapter)
        if adapter then
            local ok, result = pcall(adapter.is_open)
            snap[entry.adapter] = ok and result or false
        end
    end
    return snap
end

---@param a table<string, boolean>
---@param b table<string, boolean>
---@return boolean
local function snapshot_changed(a, b)
    for k, v in pairs(a) do
        if b[k] ~= v then
            return true
        end
    end
    for k, v in pairs(b) do
        if a[k] ~= v then
            return true
        end
    end
    return false
end

--- Redraw every icon row. Called on initial open, after clicks, and
--- by the event/timer refresh path when any adapter's is_open() changed.
function M.render()
    if not (M.buf and vim.api.nvim_buf_is_valid(M.buf)) then
        return
    end

    vim.bo[M.buf].modifiable = true
    vim.api.nvim_buf_clear_namespace(M.buf, NS, 0, -1)

    local entries = active_icons()
    -- Layout (VSCode-style activity bar):
    --   1 blank top pad
    --   for each icon: icon row + 1 blank gap
    -- Icon row cells (width=5): indicator + space + glyph + space + pad
    --   active:   "▎ x  "
    --   inactive: "  x  "
    local TOP_PAD = 1
    local GAP = 1
    local rows = {}
    line_map = {}

    for _ = 1, TOP_PAD do
        table.insert(rows, "")
    end

    local snap = {}
    for _, entry in ipairs(entries) do
        local adapter = neobar.get(entry.adapter)
        local ok, is_active = pcall(adapter.is_open)
        is_active = ok and is_active or false
        snap[entry.adapter] = is_active

        local linenr = #rows + 1
        line_map[linenr] = entry.adapter
        table.insert(rows, "") -- placeholder; filled by NuiLine below

        for _ = 1, GAP do
            table.insert(rows, "")
        end
    end

    if #rows == 0 then
        rows = { "" }
    end

    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, rows)

    for linenr, adapter_name in pairs(line_map) do
        local entry
        for _, e in ipairs(entries) do
            if e.adapter == adapter_name then
                entry = e
                break
            end
        end
        if entry then
            local is_active = snap[adapter_name]
            local line = NuiLine()
            if is_active then
                line:append("▎", "NeobarIndicator")
                line:append(" ", "NeobarIconActive")
                line:append(entry.icon, "NeobarIconActive")
                line:append("  ", "NeobarIconActive")
            else
                line:append("  ", "NeobarIcon")
                line:append(entry.icon, "NeobarIcon")
                line:append("  ", "NeobarIcon")
            end
            line:render(M.buf, NS, linenr)
        end
    end

    last_active = snap
    vim.bo[M.buf].modifiable = false
end

--- Cheap check: re-render only if any adapter's open state changed.
function M.refresh()
    if not (M.win and vim.api.nvim_win_is_valid(M.win)) then
        return
    end
    if not (M.buf and vim.api.nvim_buf_is_valid(M.buf)) then
        return
    end

    local snap = snapshot_active()
    if snapshot_changed(last_active, snap) then
        M.render()
    end
end

-- Debounced schedule so a burst of WinEnter/WinClosed events collapses
-- into one refresh on the next tick.
local function schedule_refresh()
    if refresh_pending then
        return
    end
    refresh_pending = true
    vim.schedule(function()
        refresh_pending = false
        M.refresh()
    end)
end

local function stop_refresh()
    if refresh_timer then
        refresh_timer:stop()
        refresh_timer:close()
        refresh_timer = nil
    end
    if refresh_augroup then
        vim.api.nvim_del_augroup_by_id(refresh_augroup)
        refresh_augroup = nil
    end
end

local function start_refresh()
    stop_refresh()

    refresh_augroup = vim.api.nvim_create_augroup("NeobarRefresh", { clear = true })

    -- Primary signals: windows appearing/disappearing or gaining focus
    -- (covers closing a tool from outside the bar, switching tabs, etc.)
    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed", "BufWinEnter", "BufWinLeave" }, {
        group = refresh_augroup,
        callback = schedule_refresh,
    })

    -- Soft fallback for tools whose open/close does not fire the above
    -- (or fires them before the adapter's is_open() is accurate yet).
    refresh_timer = vim.uv.new_timer()
    refresh_timer:start(REFRESH_INTERVAL_MS, REFRESH_INTERVAL_MS, vim.schedule_wrap(function()
        if not (M.win and vim.api.nvim_win_is_valid(M.win)) then
            stop_refresh()
            return
        end
        M.refresh()
    end))
end

--- Map a clicked/cursor line number (1-indexed) back to the adapter it
--- represents. Returns nil if the line is out of range (blank padding,
--- or click below the last icon).
local function adapter_for_line(linenr)
    local name = line_map[linenr]
    if not name then
        return nil
    end
    return neobar.get(name)
end

local function activate_line(linenr)
    local adapter = adapter_for_line(linenr)
    if not adapter then
        return
    end
    adapter.open()
    -- give the target plugin a moment to actually open its window
    -- before re-checking is_open() — most of these (Snacks pickers,
    -- terminals) are synchronous, but this avoids a flash of
    -- incorrect "inactive" state for anything that isn't.
    vim.defer_fn(M.render, 50)
end

local function setup_buf_keymaps(buf)
    -- 1-9 activates the Nth visible icon (by order), not by buffer line.
    for i = 1, 9 do
        vim.keymap.set("n", tostring(i), function()
            local entries = active_icons()
            local entry = entries[i]
            if not entry then
                return
            end
            local adapter = neobar.get(entry.adapter)
            if adapter then
                adapter.open()
                vim.defer_fn(M.render, 50)
            end
        end, { buffer = buf, nowait = true, silent = true })
    end

    vim.keymap.set("n", "<CR>", function()
        activate_line(vim.api.nvim_win_get_cursor(0)[1])
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "<LeftMouse>", function()
        local mouse = vim.fn.getmousepos()
        if mouse.winid ~= M.win then
            -- click landed in some other window while this buffer
            -- happened to be focused-mapped; let it behave like a
            -- normal click there instead of swallowing it
            vim.api.nvim_set_current_win(mouse.winid)
            return
        end
        activate_line(mouse.line)
    end, { buffer = buf, silent = true })
end

--- Open (or focus, if already open) the neobar window. edgy.nvim is
--- expected to immediately relocate this into its configured edgebar
--- slot based on filetype (see neobar.edgy.view()). The raw
--- position/size passed to nvim_open_win here is only a reasonable
--- fallback if edgy isn't loaded/enabled.
function M.open()
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_set_current_win(M.win)
        return
    end

    define_highlights()

    local buf = ensure_buf()

    local cfg = require("neobar").opts() or {}
    -- width must stay in sync with render() (indicator + pad + glyph + pad)
    -- and edgy's options.<side>.size. Default 5 for a readable VSCode-like bar.
    local width = cfg.width or 5
    local position = cfg.position or "left"
    local col = (position == "left") and 0 or (vim.o.columns - width)

    M.win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        width = width,
        height = vim.o.lines - 2,
        row = 0,
        col = col,
        style = "minimal",
        border = "none",
        focusable = true,
    })

    vim.wo[M.win].cursorline = false
    vim.wo[M.win].number = false
    vim.wo[M.win].relativenumber = false
    vim.wo[M.win].signcolumn = "no"
    vim.wo[M.win].wrap = false
    vim.wo[M.win].list = false
    vim.wo[M.win].winhighlight = "Normal:NeobarBg,NormalNC:NeobarBg,EndOfBuffer:NeobarBg"

    setup_buf_keymaps(buf)
    M.render()
    start_refresh()
end

--- Close the neobar window and tear down refresh watchers.
function M.close()
    stop_refresh()
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_win_close(M.win, true)
    end
    M.win = nil
end

--- Toggle: close if open, otherwise open.
function M.toggle()
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        M.close()
    else
        M.open()
    end
end

return M
