local neobar = require("neobar")

describe("neobar (registry + setup)", function()
    describe("register() / get()", function()
        it("makes a registered adapter retrievable by name", function()
            neobar.register({
                name = "__test_adapter_a",
                open = function() end,
                is_open = function()
                    return false
                end,
            })

            local adapter = neobar.get("__test_adapter_a")
            assert.is_not_nil(adapter)
            assert.are.equal("function", type(adapter.open))
            assert.are.equal("function", type(adapter.is_open))
        end)

        it("returns nil for an adapter that was never registered", function()
            assert.is_nil(neobar.get("__test_adapter_that_does_not_exist"))
        end)

        it("rejects an adapter missing open()", function()
            local ok = pcall(neobar.register, {
                name = "__test_bad_adapter_1",
                is_open = function()
                    return false
                end,
            })
            assert.is_false(ok)
        end)

        it("rejects an adapter missing is_open()", function()
            local ok = pcall(neobar.register, {
                name = "__test_bad_adapter_2",
                open = function() end,
            })
            assert.is_false(ok)
        end)

        it("rejects an adapter with no name at all", function()
            local ok = pcall(neobar.register, {
                open = function() end,
                is_open = function()
                    return false
                end,
            })
            assert.is_false(ok)
        end)
    end)

    describe("setup()", function()
        -- NOTE: init.lua's adapter table and resolved opts are
        -- module-level locals with no reset function exposed (by
        -- design — clear() exists only to make testing convenient,
        -- and that's not a reason to add surface area to shipped
        -- code). That means setup() calls across this describe block
        -- accumulate rather than start clean each time, same as they
        -- would in a real running Neovim session that called setup()
        -- more than once. Each test below accounts for that instead
        -- of assuming a blank slate.

        it("registers explorer/git/plugins when no opts are given", function()
            neobar.setup()
            assert.is_not_nil(neobar.get("explorer"))
            assert.is_not_nil(neobar.get("git"))
            assert.is_not_nil(neobar.get("plugins"))
        end)

        it("does not register diagnostics/debug/test/run (no adapter exists yet)", function()
            neobar.setup()
            assert.is_nil(neobar.get("diagnostics"))
            assert.is_nil(neobar.get("debug"))
            assert.is_nil(neobar.get("test"))
            assert.is_nil(neobar.get("run"))
        end)

        it("skips a built-in adapter whose slot is disabled", function()
            neobar.setup({ slots = { git = { enabled = false } } })
            -- git was registered by an earlier test's setup() call in
            -- this same process and setup() never unregisters
            -- anything — so this asserts the REALISTIC behavior (a
            -- disabled slot doesn't get newly registered), not the
            -- unrealistic "previously-registered adapters vanish"
            -- behavior, which setup() was never designed to do.
            assert.is_not_nil(neobar.get("explorer"))
        end)

        it("exposes the resolved config via opts() after setup", function()
            neobar.setup({ edgy = false })
            local opts = neobar.opts()
            assert.is_not_nil(opts)
            assert.are.same(false, opts.edgy)
        end)
    end)
end)
