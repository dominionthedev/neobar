# neobar

A thin, VSCode-style activity bar for Neovim — a vertical strip of icons docked to the screen edge, each one dispatching to a tool you already use.

Neobar doesn't reimplement anything. It doesn't have its own file explorer, its own git client, or its own plugin manager UI. Each icon is backed by a small **adapter** that knows how to open the real tool (`Snacks.explorer()`, `Snacks.lazygit()`, `require("lazy.view").show()`, ...) and how to ask it "are you currently open," so the icon can reflect that state.

```
┃ 
┃ 
┃ 
┃ 
```

## Status

Three of seven planned slots have a real adapter right now:

| Slot | Backs onto | State |
|---|---|---|
| explorer |  `Snacks.explorer()` | done |
| git | `Snacks.lazygit()` | done |
| plugins | lazy.nvim's own UI | done |
| diagnostics | — | not yet |
| debug | — | not yet |
| test | — | not yet |
| run | — | not yet |

The icon set and config schema for all seven already exist, so adding the remaining four adapters later won't require a config migration.

## Install

```lua
{
    "dominionthedev/neobar",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "folke/edgy.nvim",
    },
    opts = {},
}
```

That's the whole setup. With no options, neobar registers every built-in adapter that exists and opens its pinned edgy view at startup.

## Configuration

```lua
require("neobar").setup({
    edgy = true, -- false if you don't have edgy.nvim, or want to dock it yourself
    slots = {
        explorer = { enabled = true },
        git = { enabled = true },
        plugins = { enabled = true },
        diagnostics = { enabled = true },
        debug = { enabled = true },
        test = { enabled = true },
        run = { enabled = true },
    },
})
```

A slot only actually shows up if it's both `enabled = true` *and* has a real adapter (see the status table above) — disabling a not-yet-built slot has no visible effect either way.

## Commands

| Command | Does |
|---|---|
| `:Neobar` | Open the window directly, bypassing edgy |
| `:NeobarToggle` | Close it if open, otherwise open it |

## How it docks

Neobar's window is a plain floating window with `filetype = "neobar"`. [edgy.nvim](https://github.com/folke/edgy.nvim) relocates and pins *any* window matching a filetype it's configured to watch for, regardless of how that window was created — neobar doesn't need anything fancier than that one filetype to integrate.

One non-obvious thing worth knowing if you're also customizing edgy yourself: the edgebar's actual **width** comes from edgy's `options.right.size` (a sibling of the views array, not a field on the view itself). A view-level `size` field exists too, but it controls that view's share of the edgebar's *other* axis (height, for several views stacked in the same bar) — not the bar's width. Neobar's own plugin spec already sets `options.right.size` to match its content, but if you're merging neobar's edgy view into your own existing edgy config by hand, that's the field to set.

## Why no nui.split, even though nui.nvim is a dependency

nui.nvim is used for `nui.line`/`nui.text` — rendering each icon row with per-segment highlighting in one call instead of hand-rolling `nvim_buf_add_highlight` per row. The window itself is a plain `vim.api.nvim_open_win` call, not `nui.split`. edgy.nvim works on any window regardless of how it was created, so going straight to the API gives direct control over exactly what edgy needs (the filetype) without an extra layer in between.

## Full documentation

`:help neobar` once installed, or see [`doc/neobar.txt`](doc/neobar.txt).

## License

MIT
