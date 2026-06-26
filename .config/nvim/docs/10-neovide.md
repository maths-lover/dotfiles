[Documentation index](README.md)

# 10. Neovide

[Neovide](https://neovide.dev) is a GUI front-end for Neovim, used for project
work. Settings live in `lua/config/neovide.lua` and apply only when running under
Neovide (the file early-returns otherwise, so they never affect the terminal).

## Launch

```sh
neovide
```

Launch from a shell so it inherits your PATH (needed so language servers such as
the Java LSP are found).

## What is configured

| Area | Setting |
|------|---------|
| Font | `MonaspiceNe Nerd Font Mono:h14` (same family as the terminal) |
| Padding | top/bottom 8, left/right 10 (mirrors Ghostty) |
| Opacity | 0.97 (subtle, like the terminal) |
| Cursor | short animation, small trail, "railgun" particle effect |
| Scrolling | smooth scroll + window position animation |
| Window | remembers size; hides mouse while typing |
| Floats | slight blur + shadow |
| Option key | left Option acts as Meta (so `<A-...>` maps work); right Option types specials |

## macOS shortcuts (Neovide only)

| Key | Action |
|-----|--------|
| `Cmd-c` / `Cmd-v` | copy / paste (system clipboard) |
| `Cmd-s` | save |
| `Cmd-a` | select all |
| `Cmd-=` / `Cmd--` / `Cmd-0` | zoom in / out / reset |

## Theme

Neovide cannot read terminal ANSI colors, but theme-sync reads the shared
`~/.config/zsh/.active-theme` file, so Neovide picks up the same colorscheme as the
terminal. See [Theme sync](09-theme-sync.md).

## Customizing

Edit `lua/config/neovide.lua`. All keys are the standard `vim.g.neovide_*`
variables documented at the Neovide site; the file is guarded by
`if not vim.g.neovide then return end`.

---

Next: [macOS integration](11-macos-integration.md)
