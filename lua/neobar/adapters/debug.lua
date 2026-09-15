-- Debug adapter (nvim-dap-ui).
--
-- Desired layout (matches VSCode-ish debug chrome):
--   left:   scopes, stacks, breakpoints, watches
--   bottom: repl, console
--
-- dapui layouts are owned by the user's require("dapui").setup({ layouts = ... }).
-- This adapter opens/closes the whole UI and reports open when any dapui
-- window is visible. It occupies BOTH left and bottom for exclusive
-- switching (opening explorer closes debug and vice versa).
--
-- Recommended dapui layouts (also exported as neobar.dapui_layouts()):
--   1) left  x4 elements, 2) bottom x2 elements.

local LEFT_FT = {
  dapui_scopes = true,
  dapui_stacks = true,
  dapui_breakpoints = true,
  dapui_watches = true,
}

local BOTTOM_FT = {
  dapui_console = true,
  ["dap-repl"] = true,
}

local function any_dapui_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    if LEFT_FT[ft] or BOTTOM_FT[ft] or ft:match("^dapui_") then
      return true
    end
  end
  return false
end

return {
  name = "debug",
  -- Multi-edge: exclusive layout treats debug as using both sides
  sides = { "left", "bottom" },
  side = "left",

  open = function()
    local ok, dapui = pcall(require, "dapui")
    if not ok then
      vim.notify("neobar: nvim-dap-ui is not available", vim.log.levels.WARN)
      return
    end
    -- open() shows all configured layouts (left + bottom if set up that way)
    dapui.open()
  end,

  close = function()
    local ok, dapui = pcall(require, "dapui")
    if ok then
      dapui.close()
    end
  end,

  is_open = function()
    return any_dapui_window()
  end,
}
