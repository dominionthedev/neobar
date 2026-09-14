-- Debug adapter (nvim-dap-ui).
--
-- dapui has open()/close()/toggle() but no public is_open(). Open state
-- is detected by scanning for any window whose buffer filetype starts
-- with "dapui_" (dapui_scopes, dapui_breakpoints, dapui_stacks,
-- dapui_watches, dapui_console, dap-repl is related but separate).

local function any_dapui_window()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype
        if ft:match("^dapui_") or ft == "dap-repl" then
            return true
        end
    end
    return false
end

return {
    name = "debug",

    open = function()
        local ok, dapui = pcall(require, "dapui")
        if not ok then
            vim.notify("neobar: nvim-dap-ui is not available", vim.log.levels.WARN)
            return
        end
        dapui.toggle()
    end,

    is_open = function()
        return any_dapui_window()
    end,
}
