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

--- Redraw every icon row. Called on initial open and whenever any
--- adapter's is_open() might have changed (after a click, and on a
--- periodic/event-driven refresh wired in later — not built yet,
--- since that depends on the adapters that don't exist yet for
--- diagnostics/debug/test/run).
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

    for i, entry in ipairs(entries) do
        local adapter = neobar.get(entry.adapter)
        local is_active = adapter.is_open()

        local line = NuiLine()
        -- one leading space, not two — keeps this a genuinely thin
        -- bar rather than wasting half the width on padding
        line:append(" ")
        line:append(entry.icon, is_active and "NeobarIconActive" or "NeobarIcon")

        line:render(M.buf, NS, i)
    end

    vim.bo[M.buf].modifiable = false
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
--- expected to immediately relocate this into its configured `right`
--- edgebar slot based on filetype — see the edgy opts in
--- plugins/neobar.lua. The raw position/size passed to nvim_open_win
--- here is a reasonable fallback if edgy isn't loaded/enabled for some
--- reason, not the real intended layout.
function M.open()
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_set_current_win(M.win)
        return
    end

    define_highlights()

    local buf = ensure_buf()

    -- width=2 is the real minimum that fits what render() actually
    -- writes per row (" " + one glyph = 2 display cells).
    local width = 2

    M.win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        width = width,
        height = vim.o.lines - 2,
        row = 0,
        col = vim.o.columns - width,
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
end

return M
