-- Default configuration and config merging for neobar.

local M = {}

---@class neobar.SlotConfig
---@field enabled? boolean
---@field side? "left"|"right"|"bottom"|"top"  which edge the tool panel prefers

---@class neobar.CustomAdapter
---@field name string
---@field icon? string
---@field side? "left"|"right"|"bottom"|"top"
---@field open fun()
---@field is_open fun(): boolean
---@field close? fun()

---@class neobar.Config
---@field edgy? boolean
---@field position? "left"|"right"  activity bar edge (default "left")
---@field width? number  activity bar cells (default 5)
---@field exclusive? boolean  only one tool panel open per side (default true)
---@field slots? table<string, neobar.SlotConfig>
---@field adapters? neobar.CustomAdapter[]  user-defined adapters registered at setup

---@type neobar.Config
M.defaults = {
  edgy = true,
  position = "left",
  width = 5,
  exclusive = true,

  slots = {
    -- Classic VSCode-ish placement of tool panels (not the activity bar itself)
    explorer = { enabled = true, side = "left" },
    git = { enabled = true, side = "left" },
    plugins = { enabled = true, side = "left" },
    diagnostics = { enabled = true, side = "right" },
    debug = { enabled = true, side = "right" },
    test = { enabled = true, side = "right" },
    run = { enabled = true, side = "bottom" },
    terminal = { enabled = true, side = "bottom" },
  },
}

---@param opts? neobar.Config
---@return neobar.Config
function M.resolve(opts)
  return vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
