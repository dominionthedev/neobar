-- Minimal init for running neobar's test suite reproducibly.
--
-- Usage (from the neobar repo root):
--   nvim --headless -u tests/minimal_init.lua \
--     -c "PlenaryBustedDirectory tests/neobar/"
--
-- This assumes plenary.nvim and nui.nvim are already installed
-- somewhere lazy.nvim (or whatever you use) puts them — it does NOT
-- install them itself. Most of the suite (config_spec, init_spec,
-- adapters_spec, window_spec) only needs those two. adapters_live_spec
-- additionally needs Snacks.nvim and lazy.nvim actually loaded to do
-- anything beyond reporting itself as pending — that's expected, see
-- the comment at the top of that file.

local data_path = vim.fn.stdpath("data")

-- Adjust this glob if your plugins live somewhere other than the
-- standard lazy.nvim install path.
local plugin_glob = data_path .. "/lazy/*"

vim.opt.runtimepath:append(vim.fn.getcwd())
for _, path in ipairs(vim.fn.glob(plugin_glob, false, true)) do
    vim.opt.runtimepath:append(path)
end

vim.cmd("runtime plugin/plenary.vim")
