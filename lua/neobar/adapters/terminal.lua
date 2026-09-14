-- Terminal adapter.
--
-- Prefers Snacks.terminal when available (matches the rest of the
-- Snacks-based stack), otherwise falls back to toggleterm.nvim.
-- is_open scans for a terminal buffer in a non-floating window.

local function snacks_open()
  if not (Snacks and Snacks.terminal) then
    return false
  end
  Snacks.terminal()
  return true
end

local function toggleterm_open()
  local ok, toggleterm = pcall(require, "toggleterm")
  if not ok then
    return false
  end
  -- toggle() opens or focuses the default terminal
  if toggleterm.toggle then
    toggleterm.toggle()
  else
    vim.cmd("ToggleTerm")
  end
  return true
end

local function terminal_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "terminal" then
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
    return terminal_open()
  end,
}
