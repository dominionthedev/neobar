-- Icon glyphs for each neobar slot, paired with its adapter name.
--
-- All codepoints below are from the codicon set (VSCode's own icon
-- font, "cod" prefix in nerd-fonts), verified against the actual
-- nerd-fonts cheat-sheet data
-- (ryanoasis/nerd-fonts gh-pages/_posts/2017-01-04-icon-cheat-sheet.md)
-- rather than typed from memory. Several of these are literally
-- VSCode's own activity-bar icons for the equivalent concept — source
-- control (git), extensions (plugins), beaker (testing) — which fits,
-- since neobar is deliberately recreating that exact pattern.
--
-- All seven slots have real adapters (see neobar/adapters/). Icons are
-- only rendered for adapters that are registered and enabled.

return {
    { name = "explorer", adapter = "explorer", icon = "\u{EAF7}" }, -- nf-cod-folder_opened
    { name = "git", adapter = "git", icon = "\u{EA68}" }, -- nf-cod-source_control
    { name = "plugins", adapter = "plugins", icon = "\u{EAE6}" }, -- nf-cod-extensions
    { name = "diagnostics", adapter = "diagnostics", icon = "\u{EA87}" }, -- nf-cod-error
    { name = "debug", adapter = "debug", icon = "\u{EB91}" }, -- nf-cod-debug_alt
    { name = "test", adapter = "test", icon = "\u{EA79}" }, -- nf-cod-beaker
    { name = "run", adapter = "run", icon = "\u{EB2C}" }, -- nf-cod-play
}
