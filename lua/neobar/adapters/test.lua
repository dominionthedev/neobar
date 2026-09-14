-- Test adapter (neotest summary).
--
-- neotest.summary has open()/close()/toggle() but no public is_open().
-- The summary buffer uses filetype "neotest-summary" (confirmed from
-- neotest consumers). Scan open windows for that filetype.

local function summary_open()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "neotest-summary" then
            return true
        end
    end
    return false
end

return {
    name = "test",

    open = function()
        local ok, neotest = pcall(require, "neotest")
        if not ok then
            vim.notify("neobar: neotest is not available", vim.log.levels.WARN)
            return
        end
        neotest.summary.toggle()
    end,

    is_open = function()
        return summary_open()
    end,
}
