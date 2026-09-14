-- Neobar adapter layer.
--
-- This exists because the seven tools neobar will eventually dispatch
-- to (explorer, git, plugins, diagnostics, debug, test, run) have NO
-- shared interface for "open this" / "is this open right now" — each
-- is a different plugin with a different API, and several don't
-- expose any "is it open" query at all. Verified directly against
-- real source (not docs, which can lag or omit internals) for the
-- adapters built so far:
--
--   explorer (Snacks)      -> Snacks.picker.get({source="explorer"})
--   git (Snacks.lazygit)   -> Snacks.terminal.list() + cmd match
--   plugins (lazy.nvim)    -> lazy.view.visible()
--   diagnostics (trouble)  -> trouble.toggle/is_open("diagnostics")
--   debug (dapui)          -> dapui.toggle() + dapui_* filetype scan
--   test (neotest)         -> neotest.summary.toggle() + ft scan
--   run (overseer)         -> overseer.toggle() + OverseerList ft scan
--
-- Adapter contract — each file in neobar/adapters/ returns:
--   {
--     name    = "explorer",
--     open    = function() ... end,   -- calls the tool's real open/toggle
--     is_open = function() return true/false end,
--   }
--
-- Neobar's eventual UI will only ever call open()/is_open() on these
-- adapters — never the underlying plugins directly. That's the whole
-- point: when dapui/neotest/overseer adapters get built later and turn
-- out to need messier tracking (event listeners, polling), the UI
-- layer doesn't care or change at all.

local M = {}

local adapters = {}

---@type neobar.Config?
local resolved_opts = nil

--- Register an adapter. Called once per adapter at startup.
---@param adapter table
function M.register(adapter)
    assert(adapter.name, "adapter must have a name")
    assert(type(adapter.open) == "function", "adapter '" .. adapter.name .. "' must have open()")
    assert(type(adapter.is_open) == "function", "adapter '" .. adapter.name .. "' must have is_open()")
    adapters[adapter.name] = adapter
end

---@param name string
function M.get(name)
    return adapters[name]
end

--- The resolved config from the last setup() call, or nil if setup()
--- hasn't run yet. Mainly useful for other neobar modules (e.g. a
--- future edgy helper) that need to read user opts without each one
--- needing setup() called on them directly.
---@return neobar.Config?
function M.opts()
    return resolved_opts
end

--- Entry point a real lazy.nvim install calls automatically via
--- { "dominionthedev/neobar", opts = {...} }. Registers the built-in
--- adapters whose slot is enabled (all seven are enabled by default,
--- and wires the startup-open
--- autocmd unless opts.edgy = false.
---@param opts? neobar.Config
function M.setup(opts)
    resolved_opts = require("neobar.config").resolve(opts)

    local available = {
        explorer = "neobar.adapters.explorer",
        git = "neobar.adapters.git",
        plugins = "neobar.adapters.plugins",
        diagnostics = "neobar.adapters.diagnostics",
        debug = "neobar.adapters.debug",
        test = "neobar.adapters.test",
        run = "neobar.adapters.run",
    }

    for slot_name, module_path in pairs(available) do
        local slot_cfg = resolved_opts.slots[slot_name]
        if slot_cfg and slot_cfg.enabled then
            M.register(require(module_path))
        end
    end

    if resolved_opts.edgy then
        -- Open the configured edgebar on startup so the pinned
        -- activity-bar view appears. The actual view registration
        -- must still live in the user's edgy.nvim opts (see
        -- neobar.edgy.view() / README). We only call open() here.
        local position = resolved_opts.position or "left"
        vim.api.nvim_create_autocmd("VimEnter", {
            once = true,
            callback = function()
                vim.schedule(function()
                    local ok, edgy = pcall(require, "edgy")
                    if ok and edgy and edgy.open then
                        edgy.open(position)
                    end
                end)
            end,
        })
    end
end

return M
