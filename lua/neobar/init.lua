-- Neobar adapter layer + setup.
--
-- Adapter contract:
--   {
--     name    = "explorer",
--     open    = function() ... end,
--     is_open = function() return true/false end,
--     close?  = function() ... end,  -- optional; else open() is treated as toggle
--     side?   = "left"|"right"|"bottom"|"top",
--     icon?   = "…",                 -- for custom adapters only
--   }

local M = {}

local adapters = {}
---@type neobar.Config?
local resolved_opts = nil

-- Extra icon entries contributed by custom adapters (appended in UI).
local custom_icons = {}

--- Register an adapter (built-in or user). Safe to call after setup().
---@param adapter table
function M.register(adapter)
    assert(adapter.name, "adapter must have a name")
    assert(type(adapter.open) == "function", "adapter '" .. adapter.name .. "' must have open()")
    assert(type(adapter.is_open) == "function", "adapter '" .. adapter.name .. "' must have is_open()")
    adapters[adapter.name] = adapter

    if adapter.icon then
        local found = false
        for _, entry in ipairs(custom_icons) do
            if entry.adapter == adapter.name then
                entry.icon = adapter.icon
                found = true
                break
            end
        end
        if not found then
            table.insert(custom_icons, {
                name = adapter.name,
                adapter = adapter.name,
                icon = adapter.icon,
            })
        end
    end
end

---@param name string
function M.get(name)
    return adapters[name]
end

--- All registered adapters (name -> adapter).
function M.list()
    return adapters
end

--- Icon entries for custom adapters (merged by window.lua after builtins).
function M.custom_icons()
    return custom_icons
end

---@return neobar.Config?
function M.opts()
    return resolved_opts
end

---@param opts? neobar.Config
function M.setup(opts)
    resolved_opts = require("neobar.config").resolve(opts)
    custom_icons = {}

    local available = {
        explorer = "neobar.adapters.explorer",
        git = "neobar.adapters.git",
        plugins = "neobar.adapters.plugins",
        diagnostics = "neobar.adapters.diagnostics",
        debug = "neobar.adapters.debug",
        test = "neobar.adapters.test",
        run = "neobar.adapters.run",
        terminal = "neobar.adapters.terminal",
    }

    for slot_name, module_path in pairs(available) do
        local slot_cfg = resolved_opts.slots[slot_name]
        if slot_cfg and slot_cfg.enabled then
            local adapter = require(module_path)
            -- Prefer slot-level side over adapter default
            if slot_cfg.side then
                adapter.side = slot_cfg.side
            end
            M.register(adapter)
        end
    end

    -- User-defined adapters from opts.adapters = { { name, icon, open, is_open, ... }, ... }
    if resolved_opts.adapters then
        for _, adapter in ipairs(resolved_opts.adapters) do
            M.register(adapter)
        end
    end

    if resolved_opts.edgy then
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
