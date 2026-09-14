-- Edgy.nvim integration for neobar.
--
-- Neobar's window is a plain floating window with filetype = "neobar".
-- edgy.nvim relocates *any* window matching a configured filetype into
-- its edgebar, regardless of how the window was created.
--
-- This module provides the ready-to-merge view definition and the
-- recommended edgebar size so users (or neobar's own setup) can get a
-- pinned, always-visible activity bar with almost no extra config.
--
-- Typical usage in your edgy.nvim opts:
--
--   left = {
--     require("neobar.edgy").view(),
--     -- other left views...
--   },
--   options = {
--     left = { size = 5 },  -- must match the activity bar width
--   },
--
-- Or call require("neobar.edgy").view({ position = "right" }) and put
-- it under the matching side + options.right.size.

local M = {}

local FILETYPE = "neobar"
local DEFAULT_WIDTH = 5

--- Return the Edgy.View.Opts table for the activity bar.
--- @param opts? { title?: string, width?: number, collapsed?: boolean }
--- @return table
function M.view(opts)
  opts = opts or {}
  local width = opts.width or DEFAULT_WIDTH

  return {
    title = opts.title or "Neobar",
    ft = FILETYPE,
    pinned = true,
    collapsed = opts.collapsed or false,
    -- When the pinned placeholder is clicked (or edgy.open() runs),
    -- create the real neobar window so edgy can capture it by filetype.
    open = function()
      require("neobar.window").open()
    end,
    -- View-level size controls the *other* axis when multiple views
    -- share an edgebar (height for left/right bars). For a single
    -- narrow activity bar it is mostly irrelevant; the real width
    -- comes from options.left/right.size (see M.options below).
    size = { width = width },
    wo = {
      -- Keep the bar minimal; these reinforce what window.lua already sets.
      number = false,
      relativenumber = false,
      cursorline = false,
      signcolumn = "no",
      wrap = false,
      winbar = false,
    },
  }
end

--- Recommended options.<side>.size table.
--- The edgebar *width* (for left/right) is controlled here, not by the
--- view's own size field. Keep this in sync with the width used by
--- window.lua / M.view().
--- @param opts? { width?: number }
--- @return table
function M.options(opts)
  opts = opts or {}
  local width = opts.width or DEFAULT_WIDTH
  return { size = width }
end

--- Convenience: full snippet that can be merged into an edgy config.
--- @param opts? { position?: "left"|"right", title?: string, width?: number, collapsed?: boolean }
--- @return { views: table[], options: table, position: string }
function M.snippet(opts)
  opts = opts or {}
  local position = opts.position or "left"
  local width = opts.width or DEFAULT_WIDTH

  return {
    position = position,
    views = { M.view({ title = opts.title, width = width, collapsed = opts.collapsed }) },
    options = {
      [position] = M.options({ width = width }),
    },
  }
end

return M
