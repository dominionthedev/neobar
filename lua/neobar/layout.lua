-- Panel layout: which tool is active on each edge, and exclusive open.
--
-- When exclusive = true (default), opening a tool on a side closes any
-- other neobar-managed tool currently open on that same side — so you
-- get one panel per edge, switched by the activity bar (VSCode-like).

local neobar = require("neobar")

local M = {}

-- side -> adapter name currently considered active on that edge
local active = {
  left = nil,
  right = nil,
  bottom = nil,
  top = nil,
}

---@param name string
---@return "left"|"right"|"bottom"|"top"
function M.side_for(name)
  local opts = neobar.opts() or {}
  local slot = opts.slots and opts.slots[name]
  if slot and slot.side then
    return slot.side
  end
  local adapter = neobar.get(name)
  if adapter and adapter.side then
    return adapter.side
  end
  return "left"
end

---@param name string
---@return boolean
local function is_open(name)
  local adapter = neobar.get(name)
  if not adapter then
    return false
  end
  local ok, result = pcall(adapter.is_open)
  return ok and result or false
end

--- Close a tool if possible (prefer close(), else toggle via open()).
---@param name string
local function close_tool(name)
  local adapter = neobar.get(name)
  if not adapter then
    return
  end
  if not is_open(name) then
    return
  end
  if type(adapter.close) == "function" then
    pcall(adapter.close)
  else
    -- toggle-style open()
    pcall(adapter.open)
  end
end

--- Open the named adapter, enforcing exclusive-per-side when configured.
---@param name string
function M.open(name)
  local adapter = neobar.get(name)
  if not adapter then
    return
  end

  local opts = neobar.opts() or {}
  local side = M.side_for(name)
  local exclusive = opts.exclusive ~= false

  if exclusive then
    local current = active[side]
    if current and current ~= name and is_open(current) then
      close_tool(current)
    end
  end

  -- If this tool is already open, still call open() so toggle-style
  -- adapters can focus/close as their own API defines; callers that
  -- want pure focus can check is_open first.
  pcall(adapter.open)
  active[side] = name
end

---@param side? "left"|"right"|"bottom"|"top"
---@return string|nil
function M.active(side)
  if side then
    return active[side]
  end
  return nil
end

function M.reset()
  active = { left = nil, right = nil, bottom = nil, top = nil }
end

return M
