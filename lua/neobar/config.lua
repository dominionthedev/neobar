-- Default configuration and config merging for neobar.

local M = {}

---@class neobar.SlotConfig
---@field enabled? boolean
---@field side? "left"|"right"|"bottom"|"top"
---@field sides? ("left"|"right"|"bottom"|"top")[]  multi-edge tools (e.g. debug)

---@class neobar.CustomAdapter
---@field name string
---@field icon? string
---@field side? "left"|"right"|"bottom"|"top"
---@field sides? ("left"|"right"|"bottom"|"top")[]
---@field open fun()
---@field is_open fun(): boolean
---@field close? fun()

---@class neobar.Config
---@field edgy? boolean
---@field position? "left"|"right"
---@field width? number
---@field exclusive? boolean
---@field slots? table<string, neobar.SlotConfig>
---@field adapters? neobar.CustomAdapter[]

---@type neobar.Config
M.defaults = {
  edgy = true,
  position = "left",
  width = 5,
  exclusive = true,

  slots = {
    -- Activity-bar tools and preferred panel edges
    explorer = { enabled = true, side = "left" },
    git = { enabled = true, side = "right" }, -- lazygit typically right/float
    plugins = { enabled = true, side = "left" },
    diagnostics = { enabled = true, side = "right" },
    -- dapui: scopes/stacks/breakpoints/watches on left, repl/console on bottom
    debug = { enabled = true, sides = { "left", "bottom" }, side = "left" },
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
