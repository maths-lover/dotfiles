[Documentation index](README.md)

# 10. Neovide

[Neovide](https://neovide.dev) is a GUI front-end for Neovim, used for project
work. Settings live in `lua/config/neovide.lua` and apply only when running under
Neovide (the file early-returns otherwise, so they never affect the terminal).
The GUI **font** lives separately in `~/.config/neovide/config.toml` (stowed).

## Launch

```sh
neovide
```

Launch from a shell so it inherits your PATH (needed so language servers such as
the Java LSP are found).

## What is configured

| Area | Setting |
|------|---------|
| Font | `Maple Mono NF` @ 16, set in `~/.config/neovide/config.toml` (matches Ghostty; ligatures + cursive italic + cv toggles) |
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

## Font (`~/.config/neovide/config.toml`)

The GUI font is set in **`~/.config/neovide/config.toml`** (stowed) rather than
`guifont`, because that's the only place Neovide accepts OpenType features. It
matches Ghostty's Maple Mono NF exactly:

```toml
[font]
normal = ["Maple Mono NF"]
size = 16.0
features."Maple Mono NF" = ["+calt", "+liga", "+zero", "+cv01", "+cv62", "+cv65"]
```

Ligatures (`calt`/`liga`), the slashed `zero`, and `cv01/cv62/cv65` alternates all
carry over, and Neovide uses Maple's real cursive **Italic** face automatically.
`ss06` is left out so the italic keeps its connected strokes. Restart Neovide to
apply font changes.

## Customizing

Edit `lua/config/neovide.lua`. All keys are the standard `vim.g.neovide_*`
variables documented at the Neovide site; the file is guarded by
`if not vim.g.neovide then return end`. Restart Neovide to pick up font changes.

---

Next: [macOS integration](11-macos-integration.md)
