-- window.lua's render() calls each registered adapter's is_open(), so
-- these tests register STUB adapters rather than relying on the real
-- explorer/git/plugins ones — isolates the render/width/padding logic
-- (what this file actually owns) from whether Snacks/lazy.nvim happen
-- to be loaded in whatever environment runs the test suite.

local neobar = require("neobar")
local window = require("neobar.window")

describe("neobar.window render()", function()
    before_each(function()
        -- fresh buffer per test so line counts/content from a
        -- previous test can't leak into the next one
        window.buf = vim.api.nvim_create_buf(false, true)
        vim.bo[window.buf].filetype = "neobar"

        neobar.register({
            name = "explorer",
            open = function() end,
            is_open = function()
                return false
            end,
        })
        neobar.register({
            name = "git",
            open = function() end,
            is_open = function()
                return true
            end,
        })
        neobar.register({
            name = "plugins",
            open = function() end,
            is_open = function()
                return false
            end,
        })
    end)

    it("renders one line per visible icon", function()
        window.render()
        local lines = vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)
        -- icons.lua lists 7 slots, but only explorer/git/plugins have
        -- a registered adapter — diagnostics/debug/test/run should
        -- not produce a row
        assert.are.equal(3, #lines)
    end)

    it("pads every rendered line to exactly 3 display cells", function()
        window.render()
        local lines = vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)
        for _, line in ipairs(lines) do
            assert.are.equal(3, vim.fn.strdisplaywidth(line))
        end
    end)

    it("does not error when re-rendered repeatedly", function()
        -- render() is called again after every activation in real
        -- use (see activate_line()'s defer_fn) — this guards against
        -- anything that only works once (e.g. forgetting to clear the
        -- namespace before re-adding highlights)
        local ok = pcall(function()
            window.render()
            window.render()
            window.render()
        end)
        assert.is_true(ok)
    end)
end)
