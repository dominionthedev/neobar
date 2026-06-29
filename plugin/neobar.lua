-- Auto-loaded by Neovim's plugin/ mechanism once neobar is installed
-- (no explicit require needed for this file specifically — anything
-- under plugin/ in a runtimepath-visible plugin is sourced at startup
-- automatically). User commands belong here rather than in
-- lua/neobar/init.lua's setup() so they exist even if, for some
-- reason, setup() hasn't run yet — though M.open()/M.toggle() will
-- still assert that setup() has run before doing real work.

if vim.g.loaded_neobar then
    return
end
vim.g.loaded_neobar = true

vim.api.nvim_create_user_command("Neobar", function()
    require("neobar.window").open()
end, { desc = "Open neobar" })

vim.api.nvim_create_user_command("NeobarToggle", function()
    local window = require("neobar.window")
    if window.win and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_close(window.win, true)
    else
        window.open()
    end
end, { desc = "Toggle neobar" })
