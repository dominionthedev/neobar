-- Git adapter (Snacks.lazygit).
--
-- is_open: Snacks.terminal.list() filtered to cmds containing "lazygit".
-- Deliberately separate from the terminal adapter so a normal shell
-- terminal does not light up the git icon and vice versa.

local function cmd_str(cmd)
  if type(cmd) == "table" then
    return table.concat(cmd, " ")
  end
  return tostring(cmd or "")
end

local function find_lazygit_terminal()
  if not (Snacks and Snacks.terminal and Snacks.terminal.list) then
    return nil
  end
  local ok, terminals = pcall(Snacks.terminal.list)
  if not ok or not terminals then
    return nil
  end
  for _, term in ipairs(terminals) do
    if cmd_str(term.cmd):find("lazygit", 1, true) and term:valid() then
      return term
    end
  end
  return nil
end

return {
  name = "git",
  side = "right",

  open = function()
    if not (Snacks and Snacks.lazygit) then
      vim.notify("neobar: Snacks.lazygit is not available", vim.log.levels.WARN)
      return
    end
    Snacks.lazygit()
  end,

  is_open = function()
    return find_lazygit_terminal() ~= nil
  end,
}
