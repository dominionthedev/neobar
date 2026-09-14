-- Default configuration and config merging for neobar.
--
-- Deliberately minimal right now: window.lua's width/padding are
-- still simple hardcoded values (proven correct through real testing
-- in a live Neovim session, not just reasoned about) rather than
-- driven through this config yet. Re-plumbing every internal constant
-- through opts before any of it has been used for real risks
-- reintroducing the exact kind of untested-assumption bugs this
-- project has already hit twice (the edgy view-vs-edgebar size
-- confusion, the missing highlight group definitions). This config
-- module covers the options that are genuinely safe to expose now:
-- whether neobar manages its own edgy integration at all, which side
-- the bar should live on, the width, and which adapters/slots are enabled.

local M = {}

---@class neobar.SlotConfig
---@field enabled? boolean

---@class neobar.Config
---@field edgy? boolean   if true (default), neobar registers a VimEnter
---                       autocmd that opens its pinned edgy view at
---                       startup. Set false if you'd rather call
---                       require("edgy").open(...) yourself, or
---                       don't use edgy at all.
---@field position? "left"|"right"  which edgebar the activity bar belongs to.
---                                 Default "left" (classic VSCode).
---@field width? number   display cells for the activity bar. Must stay in
---                       sync with the padding used in window.lua render
---                       and with edgy's options.<side>.size. Default 5.
---@field slots? table<string, neobar.SlotConfig>

---@type neobar.Config
M.defaults = {
  edgy = true,
  position = "left",
  width = 5,

  slots = {
    explorer = { enabled = true },
    git = { enabled = true },
    plugins = { enabled = true },
    diagnostics = { enabled = true },
    debug = { enabled = true },
    test = { enabled = true },
    run = { enabled = true },
  },
}

---@param opts? neobar.Config
---@return neobar.Config
function M.resolve(opts)
  return vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
