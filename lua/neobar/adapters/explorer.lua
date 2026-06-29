-- Explorer adapter. The clean case: Snacks.picker.get({source="explorer"})
-- returns an array of currently-open explorer picker instances — this is
-- real, public, documented Snacks API (confirmed via folke/snacks.nvim
-- discussion #2179, which uses exactly this pattern to detect explorer
-- state before deciding whether to open/focus/close it).

return {
    name = "explorer",

    open = function()
        Snacks.explorer()
    end,

    is_open = function()
        local instances = Snacks.picker.get({ source = "explorer" })
        return #instances > 0
    end,
}
