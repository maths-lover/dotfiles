[Documentation index](README.md)

# 11. Troubleshooting

| Symptom | Fix |
|---------|-----|
| Boxes / missing icons | Terminal (or Neovide) font must be a Monaspice Nerd Font; check the font setting and reinstall the cask with `brew bundle` |
| Plugin missing or erroring | `:Lazy sync` to install/update/clean to match the specs; `:Lazy log` for details |
| LSP not attaching | `:LspInfo` to see clients; `:Mason` to confirm the server is installed; ensure the language toolchain is on PATH |
| Server/formatter not installed | `:Mason` then install it, or check `ensure_installed` in `lua/plugins/lsp.lua` / `lua/plugins/formatting.lua` |
| Format on save not working | `:ConformInfo`; check the filetype is in `formatters_by_ft`; re-enable with `:FormatEnable` if you disabled it |
| Treesitter highlight broken | `:TSUpdate`; confirm the parser is in `ensure_installed` in `lua/plugins/treesitter.lua` |
| Colorscheme does not match terminal | `:ThemeSync`; verify `~/.config/zsh/.active-theme` exists and the name is mapped in `lua/config/theme.lua` |
| Java LSP (jdtls) not starting | needs `java` on PATH; openjdk is keg-only, wired in `.zprofile`; launch nvim/neovide from a login shell |
| Neovide settings ignored | they only apply under Neovide (`vim.g.neovide` guard); in the terminal they are intentionally skipped |
| `<A-...>` mappings do nothing in Neovide | left Option must map to Meta; set in `lua/config/neovide.lua` (already configured) |
| Slow startup | `:Lazy profile` to find the culprit; most plugins are event/key-lazy by design |

## Useful commands

```vim
:checkhealth            " overall health (providers, treesitter, lazy, mason)
:Lazy                   " plugin manager UI
:Mason                  " LSP/formatter installer UI
:LspInfo                " attached LSP clients for the buffer
:ConformInfo            " formatters for the buffer
:TSUpdate               " update treesitter parsers
:ThemeSync              " re-sync colorscheme with the OS theme
```

---

[Documentation index](README.md) - [Neovim README](../README.md)
