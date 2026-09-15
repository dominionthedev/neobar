-- Panel layout: exclusive tool-per-side switching.
--
-- Adapters may declare a single `side` or multiple `sides` (e.g. debug
-- uses left + bottom for dapui). When exclusive is on, opening a tool
-- closes any other open neobar tool that shares at least one side.

local neobar = require("neobar")

local M = {}

-- side -> adapter name last activated on that edge
local active = {
  left = nil,
  right = nil,
  bottom = nil,
  top = nil,
}

---@param name string
---@return string[]
function M.sides_for(name)
  local opts = neobar.opts() or {}
  local slot = opts.slots and opts.slots[name]
  local adapter = neobar.get(name)

  if slot and slot.sides then
    return slot.sides
  end
  if adapter and adapter.sides then
    return adapter.sides
  end

  local side = (slot and slot.side) or (adapter and adapter.side) or "left"
  return { side }
end

---@param name string
---@return string
function M.side_for(name)
  return M.sides_for(name)[1] or "left"
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

---@param name string
local function close_tool(name)
  local adapter = neobar.get(name)
  if not adapter or not is_open(name) then
    return
  end
  if type(adapter.close) == "function" then
    pcall(adapter.close)
  else
    pcall(adapter.open) -- toggle-style
  end
end

--- Whether two side lists overlap.
local function shares_side(sides_a, sides_b)
  local set = {}
  for _, s in ipairs(sides_a) do
    set[s] = true
  end
  for _, s in ipairs(sides_b) do
    if set[s] then
      return true
    end
  end
  return false
end

--- Open the named adapter, enforcing exclusive-per-side when configured.
---@param name string
function M.open(name)
  local adapter = neobar.get(name)
  if not adapter then
    return
  end

  local opts = neobar.opts() or {}
  local sides = M.sides_for(name)
  local exclusive = opts.exclusive ~= false

  if exclusive then
    for other_name, _ in pairs(neobar.list()) do
      if other_name ~= name and is_open(other_name) then
        if shares_side(sides, M.sides_for(other_name)) then
          close_tool(other_name)
        end
      end
    end
  end

  pcall(adapter.open)

  for _, side in ipairs(sides) do
    active[side] = name
  end
end

---@param side? string
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
