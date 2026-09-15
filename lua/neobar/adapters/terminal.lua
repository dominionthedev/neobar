-- Terminal adapter.
--
-- Prefers Snacks.terminal when available, otherwise toggleterm.nvim.
-- Must NOT treat Snacks.lazygit terminals as a normal terminal — those
-- belong to the git adapter only.

local function cmd_str(cmd)
  if type(cmd) == "table" then
    return table.concat(cmd, " ")
  end
  return tostring(cmd or "")
end

local function is_lazygit_cmd(cmd)
  return cmd_str(cmd):find("lazygit", 1, true) ~= nil
end

--- True if this buffer is a lazygit session (name / title heuristics).
local function is_lazygit_buf(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name:find("lazygit", 1, true) then
    return true
  end
  local title = vim.b[buf].term_title or vim.b[buf].term_cmd
  if title and tostring(title):find("lazygit", 1, true) then
    return true
  end
  return false
end

local function snacks_open()
  if not (Snacks and Snacks.terminal and Snacks.terminal.open) then
    if Snacks and Snacks.terminal then
      -- Snacks.terminal() callable form
      Snacks.terminal()
      return true
    end
    return false
  end
  Snacks.terminal()
  return true
end

local function toggleterm_open()
  local ok = pcall(require, "toggleterm")
  if not ok then
    return false
  end
  vim.cmd("ToggleTerm")
  return true
end

--- Non-lazygit terminal visible in a normal (non-float) window.
local function normal_terminal_open()
  -- Prefer Snacks list when available: precise cmd filter
  if Snacks and Snacks.terminal and Snacks.terminal.list then
    local ok, terminals = pcall(Snacks.terminal.list)
    if ok and terminals then
      for _, term in ipairs(terminals) do
        if term:valid() and not is_lazygit_cmd(term.cmd) then
          return true
        end
      end
      return false
    end
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "terminal" and not is_lazygit_buf(buf) then
        return true
      end
    end
  end
  return false
end

return {
  name = "terminal",
  side = "bottom",

  open = function()
    if snacks_open() then
      return
    end
    if toggleterm_open() then
      return
    end
    vim.notify("neobar: no terminal backend (Snacks.terminal or toggleterm.nvim)", vim.log.levels.WARN)
  end,

  is_open = function()
    return normal_terminal_open()
  end,
}
