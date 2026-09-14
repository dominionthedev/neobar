-- Auto-loaded by Neovim's plugin/ mechanism once neobar is installed.

if vim.g.loaded_neobar then
    return
end
vim.g.loaded_neobar = true

vim.api.nvim_create_user_command("Neobar", function()
    require("neobar.window").open()
end, { desc = "Open neobar" })

vim.api.nvim_create_user_command("NeobarToggle", function()
    require("neobar.window").toggle()
end, { desc = "Toggle neobar" })

vim.api.nvim_create_user_command("NeobarClose", function()
    require("neobar.window").close()
end, { desc = "Close neobar" })

vim.api.nvim_create_user_command("NeobarFocus", function()
    require("neobar.window").focus()
end, { desc = "Focus neobar (open if needed)" })
