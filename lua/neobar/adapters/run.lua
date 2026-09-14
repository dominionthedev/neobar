-- Run / task adapter (overseer.nvim).
--
-- Overseer exposes toggle() for its task list. is_open is detected via
-- filetype "OverseerList" (the task list window). Falls back to a
-- quiet no-op notify if overseer is not installed.

local function list_open()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "OverseerList" then
            return true
        end
    end
    return false
end

return {
    name = "run",

    open = function()
        local ok, overseer = pcall(require, "overseer")
        if not ok then
            vim.notify("neobar: overseer.nvim is not available", vim.log.levels.WARN)
            return
        end
        overseer.toggle()
    end,

    is_open = function()
        return list_open()
    end,
}
