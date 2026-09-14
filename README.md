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

All seven slots have a real adapter:

| Slot | Backs onto | State |
|---|---|---|
| explorer | `Snacks.explorer()` | done |
| git | `Snacks.lazygit()` | done |
| plugins | lazy.nvim UI (`lazy.view`) | done |
| diagnostics | trouble.nvim (`diagnostics` mode) | done |
| debug | nvim-dap-ui | done |
| test | neotest summary | done |
| run | overseer.nvim task list | done |

Adapters that depend on a plugin you don't have installed still register, but `open()` notifies and no-ops; `is_open()` returns false.

## Install (recommended — VSCode-like layout)

Neobar provides a ready-made edgy view. Put the activity bar on the **left** (classic VSCode) and let edgy manage the rest of the layout:

```lua
{
  "dominionthedev/neobar",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "folke/edgy.nvim",
  },
  opts = {
    -- defaults: edgy = true, position = "left", width = 3
  },
},

{
  "folke/edgy.nvim",
  event = "VeryLazy",
  init = function()
    vim.opt.laststatus = 3
    vim.opt.splitkeep = "screen"
  end,
  opts = function()
    local neobar_edgy = require("neobar.edgy")
    return {
      left = {
        -- Activity bar (pinned, always visible)
        neobar_edgy.view(),
        -- Add your other left-side tools here, e.g.:
        -- { title = "Explorer", ft = "neo-tree", filter = ..., pinned = true, open = "Neotree filesystem" },
      },
      -- bottom = { ... }, right = { ... },
      options = {
        left = neobar_edgy.options(), -- { size = 3 }
      },
    }
  end,
},
```

With the above, neobar registers its adapters and, on `VimEnter`, calls `edgy.open("left")` so the pinned activity bar appears immediately.

### Minimal / no-edgy install

```lua
{
  "dominionthedev/neobar",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = { edgy = false },
}
```

Then open it yourself with `:Neobar` or `:NeobarToggle`.

## Configuration

```lua
require("neobar").setup({
  edgy = true,          -- open the edgebar on startup
  position = "left",    -- "left" | "right"  (must match your edgy side)
  width = 3,            -- display cells; keep in sync with edgy options.<side>.size
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

A slot only appears if it is both `enabled = true` **and** has a real adapter (see the status table). Disabling a not-yet-built slot has no visible effect.

### Helper for your edgy config

```lua
local neobar_edgy = require("neobar.edgy")

-- Single view ready to drop into left = { ... } or right = { ... }
neobar_edgy.view()                    -- defaults
neobar_edgy.view({ title = "Activity", width = 3, collapsed = false })

-- Matching options.<side> entry
neobar_edgy.options()                 -- { size = 3 }
neobar_edgy.options({ width = 4 })

-- Full snippet if you prefer
local s = neobar_edgy.snippet({ position = "left" })
-- s.views, s.options, s.position
```

## Commands

| Command | Does |
|---|---|
| `:Neobar` | Open the window directly (edgy will still capture it by filetype) |
| `:NeobarToggle` | Close it if open, otherwise open it |

## How it docks

Neobar's window is a plain floating window with `filetype = "neobar"`. edgy.nvim relocates and pins **any** window matching a filetype it is configured to watch for.

Important size rule:

- The edgebar **width** (left/right) comes from `options.left.size` / `options.right.size`.
- A view-level `size` field only controls the *other* axis (height when several views share the same edgebar).

`neobar.edgy.options()` returns the correct `{ size = 3 }` table so you do not have to remember the distinction.

## Why no nui.split, even though nui.nvim is a dependency

nui.nvim is used for `nui.line`/`nui.text` — rendering each icon row with per-segment highlighting in one call instead of hand-rolling `nvim_buf_add_highlight` per row. The window itself is a plain `vim.api.nvim_open_win` call, not `nui.split`. edgy.nvim works on any window regardless of how it was created, so going straight to the API gives direct control over exactly what edgy needs (the filetype) without an extra layer in between.

## Testing

```sh
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/neobar/"
```

Requires `plenary.nvim` and `nui.nvim` already installed wherever your plugin manager puts them (`tests/minimal_init.lua` globs `~/.local/share/nvim/lazy/*` by default).

Most of the suite (`config_spec`, `init_spec`, `adapters_spec`, `window_spec`) tests the registry, config merging, adapter contracts, and rendering in isolation, using stub adapters rather than the real Snacks/lazy.nvim calls. `adapters_live_spec` exercises the *real* `is_open()` functions and reports itself as **pending** (not failing) if `Snacks`/`lazy.nvim` aren't loaded — that's expected outside a full Neovim session with the actual plugin set installed.

## Full documentation

`:help neobar` once installed, or see [`doc/neobar.txt`](doc/neobar.txt).

## License

MIT
