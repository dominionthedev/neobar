-- Neobar adapter layer.
--
-- This exists because the seven tools neobar will eventually dispatch
-- to (explorer, git, plugins, diagnostics, debug, test, run) have NO
-- shared interface for "open this" / "is this open right now" — each
-- is a different plugin with a different API, and several don't
-- expose any "is it open" query at all. Verified directly against
-- real source (not docs, which can lag or omit internals) for the
-- three built so far:
--
--   explorer (Snacks)   -> Snacks.picker.get({source="explorer"})
--                          returns live picker instances; #list > 0
--                          means open. Real, public, documented.
--   git (Snacks.lazygit) -> NO public is-open query. Snacks.lazygit is
--                          built on Snacks.terminal, which DOES expose
--                          terminal.list() returning live snacks.win
--                          instances with a `.cmd` field. Filtering
--                          list() for an instance whose cmd matches
--                          "lazygit" and is :valid() is the real
--                          mechanism — confirmed by reading
--                          snacks/terminal.lua and snacks/win.lua
--                          directly, not assumed from docs.
--   plugins (lazy.nvim)  -> NO public is-open query either. lazy.nvim's
--                          UI window's buffer gets filetype = "lazy"
--                          (confirmed in lazy/view/float.lua) — so
--                          this adapter scans open windows for that
--                          filetype directly via the Neovim API, which
--                          doesn't depend on lazy.nvim exposing
--                          anything at all.
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
--- but only explorer/git/plugins have a real adapter as of this
--- release — see neobar/adapters/), and wires the startup-open
--- autocmd unless opts.edgy = false.
---@param opts? neobar.Config
function M.setup(opts)
    resolved_opts = require("neobar.config").resolve(opts)

    local available = {
        explorer = "neobar.adapters.explorer",
        git = "neobar.adapters.git",
        plugins = "neobar.adapters.plugins",
        -- diagnostics/debug/test/run intentionally absent — there is
        -- no adapter module for them yet. Listing a module path here
        -- that doesn't exist would turn "user disabled this slot"
        -- and "this slot isn't built yet" into the same silent
        -- failure mode, which defeats the point of having `enabled`
        -- be a meaningful flag at all.
    }

    for slot_name, module_path in pairs(available) do
        local slot_cfg = resolved_opts.slots[slot_name]
        if slot_cfg and slot_cfg.enabled then
            M.register(require(module_path))
        end
    end

    if resolved_opts.edgy then
        vim.api.nvim_create_autocmd("VimEnter", {
            once = true,
            callback = function()
                vim.schedule(function()
                    local ok = pcall(require, "edgy")
                    if ok then
                        require("edgy").open("right")
                    end
                end)
            end,
        })
    end
end

return M
