-- Recommended nvim-dap-ui layouts for use with neobar.
--
-- Drop into your dapui setup:
--
--   require("dapui").setup({
--     layouts = require("neobar.dapui").layouts(),
--     ...
--   })
--
-- left:  scopes, stacks, breakpoints, watches
-- bottom: repl, console

local M = {}

function M.layouts()
  return {
    {
      elements = {
        { id = "scopes", size = 0.30 },
        { id = "stacks", size = 0.30 },
        { id = "breakpoints", size = 0.20 },
        { id = "watches", size = 0.20 },
      },
      size = 40,
      position = "left",
    },
    {
      elements = {
        { id = "repl", size = 0.5 },
        { id = "console", size = 0.5 },
      },
      size = 12,
      position = "bottom",
    },
  }
end

return M
