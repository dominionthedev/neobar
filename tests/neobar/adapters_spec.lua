-- Contract-shape tests only: confirms each built-in adapter module
-- returns something satisfying {name, open, is_open}. Does NOT call
-- open()/is_open() for real, since explorer/git/plugins all reach
-- into Snacks globals or require("lazy.view") — whether those exist
-- depends on the full plugin set being loaded, not just plenary +
-- nui.nvim. See adapters_live_spec.lua for tests that DO call the
-- real functions, and skip themselves cleanly when those globals
-- aren't present (e.g. running tests via :PlenaryBustedDirectory
-- against a minimal init rather than the user's full Neovim config).

local function assert_contract(adapter, expected_name)
    assert.is_not_nil(adapter, expected_name .. " adapter module returned nil")
    assert.are.equal(expected_name, adapter.name)
    assert.are.equal("function", type(adapter.open))
    assert.are.equal("function", type(adapter.is_open))
end

describe("built-in adapter contracts", function()
    it("explorer adapter satisfies {name, open, is_open}", function()
        assert_contract(require("neobar.adapters.explorer"), "explorer")
    end)

    it("git adapter satisfies {name, open, is_open}", function()
        assert_contract(require("neobar.adapters.git"), "git")
    end)

    it("plugins adapter satisfies {name, open, is_open}", function()
        assert_contract(require("neobar.adapters.plugins"), "plugins")
    end)
end)
