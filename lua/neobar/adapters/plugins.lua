-- Plugins adapter (lazy.nvim's own UI). Correction from an earlier
-- draft: I initially wrote this against require("lazy").show() and a
-- hand-rolled window scan for filetype "lazy", assuming lazy.nvim had
-- no public is-open query. Reading lazy/view/init.lua directly showed
-- that was wrong on the first point and unnecessary on the second:
--
--   require("lazy").show() doesn't exist — the real function is
--   require("lazy.view").show(mode), defined in lazy/view/init.lua.
--
--   lazy.nvim DOES already have a real, public M.visible() in that
--   same file (`return M.view and M.view.win and
--   vim.api.nvim_win_is_valid(M.view.win)`) — so the window-filetype
--   scan I'd built as a fallback was solving an already-solved
--   problem. Using the real function instead of reinventing it.

return {
    name = "plugins",

    open = function()
        require("lazy.view").show()
    end,

    is_open = function()
        return require("lazy.view").visible() and true or false
    end,
}
