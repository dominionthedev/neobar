-- Git adapter (Snacks.lazygit). Unlike explorer, there is NO public
-- "is lazygit open" query — Snacks.lazygit.open() is built on
-- Snacks.terminal, and the `win = { style = "lazygit" }` field it
-- passes is only used to merge in default config at construction time
-- (snacks/win.lua line ~246: `ret.style = nil` — it's deliberately
-- NOT kept on the live instance, so checking instance.opts.style later
-- doesn't work).
--
-- What IS confirmed real and queryable, from reading
-- snacks/terminal.lua directly: M.list() returns every live terminal
-- snacks.win instance, and each instance stores the command it was
-- launched with on self.cmd. So this adapter lists all live terminals
-- and checks whether any of them was launched with a command
-- containing "lazygit" and is still :valid() (a real method on
-- snacks.win — confirmed it checks win+buf validity AND that the
-- window's current buffer still matches, not just "did this exist at
-- some point").
--
-- This will also need updating later when the user's own lazygit-nvim
-- integration plugin replaces Snacks.lazygit() as the open mechanism —
-- noted in the comment so future-me doesn't forget this is a stopgap
-- tied to the CURRENT git tool choice, not a permanent design.

local function find_lazygit_terminal()
    local terminals = Snacks.terminal.list()
    for _, term in ipairs(terminals) do
        local cmd = term.cmd
        local cmd_str = type(cmd) == "table" and table.concat(cmd, " ") or tostring(cmd or "")
        if cmd_str:find("lazygit", 1, true) and term:valid() then
            return term
        end
    end
    return nil
end

return {
    name = "git",

    open = function()
        Snacks.lazygit()
    end,

    is_open = function()
        return find_lazygit_terminal() ~= nil
    end,
}
