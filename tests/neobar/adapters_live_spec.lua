-- These tests call the REAL open()/is_open() functions, not just
-- check the contract shape. They only make sense when Snacks.nvim and
-- lazy.nvim are actually loaded — which is true in a real running
-- Neovim session with the user's full plugin set, but NOT true if
-- these tests are run via something like
-- `nvim --headless -u NONE -c "PlenaryBustedDirectory tests/"` against
-- a bare init with only plenary+nui on the runtimepath (the kind of
-- minimal environment used to verify this project doesn't have syntax
-- errors, earlier in this project's history).
--
-- Rather than fail confusingly in that minimal case, each describe
-- block below checks for its real dependency first and uses
-- `pending()` (plenary's real, documented way to mark a test as
-- skipped rather than failed) if it's missing.

describe("explorer adapter (live)", function()
    if _G.Snacks == nil then
        pending("Snacks global not loaded — run inside a real Neovim session with snacks.nvim installed")
        return
    end

    local explorer = require("neobar.adapters.explorer")

    it("is_open() returns a boolean", function()
        local result = explorer.is_open()
        assert.are.equal("boolean", type(result))
    end)
end)

describe("git adapter (live)", function()
    if _G.Snacks == nil then
        pending("Snacks global not loaded — run inside a real Neovim session with snacks.nvim installed")
        return
    end

    local git = require("neobar.adapters.git")

    it("is_open() returns a boolean", function()
        local result = git.is_open()
        assert.are.equal("boolean", type(result))
    end)
end)

describe("plugins adapter (live)", function()
    local ok = pcall(require, "lazy.view")
    if not ok then
        pending("lazy.view module not available — run inside a real Neovim session with lazy.nvim installed")
        return
    end

    local plugins_adapter = require("neobar.adapters.plugins")

    it("is_open() returns a boolean", function()
        local result = plugins_adapter.is_open()
        assert.are.equal("boolean", type(result))
    end)
end)
