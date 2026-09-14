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
    vim.api.nvim_set_hl(0, "NeobarIcon", { link = "Comment", default = true })
    vim.api.nvim_set_hl(0, "NeobarIconActive", { link = "Function", default = true })
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
    local total_lines = math.max(#entries, 1)
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, {})
    -- pad with blank lines up front so render() (which targets a
    -- specific line number) always has a line to write into
    vim.api.nvim_buf_set_lines(M.buf, 0, total_lines, false, vim.fn["repeat"]({ "" }, total_lines))

    local snap = {}
    for i, entry in ipairs(entries) do
        local adapter = neobar.get(entry.adapter)
        local ok, is_active = pcall(adapter.is_open)
        is_active = ok and is_active or false
        snap[entry.adapter] = is_active

        local line = NuiLine()
        -- one space on each side of the glyph — width=3 below is
        -- sized exactly for this (" " + glyph + " " = 3 cells)
        line:append(entry.icon, is_active and "NeobarIconActive" or "NeobarIcon")

        line:render(M.buf, NS, i)
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
    local entries = active_icons()
    local entry = entries[linenr]
    if not entry then
        return nil
    end
    return neobar.get(entry.adapter), entry
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
    -- Direct keybind per icon: 1-7 selects the Nth visible row,
    -- independent of cursor position. This satisfies "click works, but
    -- each icon also has a direct keybind" without needing per-adapter
    -- named keys yet (e.g. a dedicated "e" for explorer) — revisit if
    -- that granularity turns out to matter once this is actually used
    -- day to day.
    for i = 1, #icons do
        vim.keymap.set("n", tostring(i), function()
            activate_line(i)
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
    -- width must stay in sync with:
    --   1. the per-row padding in render() (" " + glyph + " " ≈ 3 cells)
    --   2. edgy's options.<side>.size (the real dock width)
    --   3. neobar.edgy.view() / neobar.edgy.options()
    local width = cfg.width or 3
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
