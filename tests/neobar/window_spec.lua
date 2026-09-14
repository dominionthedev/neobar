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

    it("renders top pad + icon rows + gaps for each visible icon", function()
        window.render()
        local lines = vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)
        -- 3 registered adapters -> 1 top pad + 3*(icon + gap) = 7 lines
        assert.are.equal(7, #lines)
    end)

    it("pads icon rows to 5 display cells (indicator + glyph + padding)", function()
        window.render()
        local lines = vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)
        -- only non-blank lines (icon rows) must be width 5
        local icon_rows = 0
        for _, line in ipairs(lines) do
            if line ~= "" then
                icon_rows = icon_rows + 1
                assert.are.equal(5, vim.fn.strdisplaywidth(line))
            end
        end
        assert.are.equal(3, icon_rows)
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
