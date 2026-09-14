-- Diagnostics adapter (trouble.nvim).
--
-- Trouble exposes a clean public API:
--   require("trouble").toggle("diagnostics")
--   require("trouble").is_open("diagnostics")
-- Confirmed from trouble/api.lua (is_open returns whether _find_last
-- found a live view for the mode).

return {
    name = "diagnostics",

    open = function()
        local ok, trouble = pcall(require, "trouble")
        if not ok then
            vim.notify("neobar: trouble.nvim is not available", vim.log.levels.WARN)
            return
        end
        trouble.toggle("diagnostics")
    end,

    is_open = function()
        local ok, trouble = pcall(require, "trouble")
        if not ok then
            return false
        end
        return trouble.is_open("diagnostics") and true or false
    end,
}
