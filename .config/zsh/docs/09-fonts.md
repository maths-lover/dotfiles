[← Documentation index](README.md)

# 9. Fonts

**Monaspace Nerd Fonts**, installed via Homebrew:

```ruby
# Brewfile
cask "font-monaspice-nerd-font"
# extra crisp Nerd Fonts to try with the `font` switcher:
cask "font-jetbrains-mono-nerd-font"
cask "font-maple-mono-nf"
cask "font-iosevka-nerd-font"
cask "font-geist-mono-nerd-font"
cask "font-commit-mono-nerd-font"
```

The Nerd Font project shortens the Monaspace cut names (Neon→Ne, Argon→Ar,
Krypton→Kr, Radon→Rn, Xenon→Xe). The terminal uses three cuts for visual flair —
configured in `~/.config/ghostty/config`:

| Role | Family | Monaspace cut |
|------|--------|---------------|
| regular | `MonaspiceNe Nerd Font Mono` | Neon (neo-grotesque) |
| italic / bold-italic | `MonaspiceRn Nerd Font Mono` | Radon (cursive — great for comments) |
| bold | `MonaspiceXe Nerd Font Mono` | Xenon (slab serif) |

`font-size = 16` with `font-thicken = false` is tuned for a 27" 4K panel:
thickening fattens strokes on low-DPI screens but only softens text on hi-DPI, so
it's off here for crisp glyphs. The enabled `font-feature`s depend on the active
font — see the Maple section below (the current pick).

> The **Mono** variant is used so Nerd Font icons occupy a single cell — correct for
> a terminal. To verify what's installed:
> `ghostty +list-fonts | grep Monaspice`

## Maple Mono (current font) — features & cursive italic

Maple Mono NF is the active font, with a feature set generated at the
[maple-font site](https://font.subf.dev) and mirrored into both `ghostty/config`
and `~/.config/neovide/config.toml` (identical lists — the source of truth).
Enabled:

- **Tags:** `calt` renders `TODO: FIXME: NOTE: INFO: WARN: HACK: ERROR: DEBUG:
  FATAL: TRACE: MARK:` as badges (add the trailing `:`); `ss03` matches them in
  any case. The badge *shape* comes from the font; the *colour* still comes from
  your editor (e.g. todo-comments.nvim).
- **Extra ligatures:** `ss07` (`>>`), `ss08` (double / reverse arrows), `ss10`
  (`≈`), `ss11` (`=` + punctuation).
- **Glyph alternates:** `cv09` (`7` with middle bar), `cv43` (italic `z`/`Z` with
  middle bar), `cv66` (pipe arrows).
- **Dotted zero:** `zero` is enabled — in Maple this feature draws the dotted zero
  (center dot), which is what you want.

The cursive **Italic** face is used automatically (`ss06` left off). To change the
set, edit the two config files or re-generate at the site and re-map.

**Cursive italic:** it comes from the Italic face (`font-family-italic = "Maple
Mono NF"`) and shows wherever a program requests italics (comments, `man` pages,
…). The important bit is that **`ss06` is NOT enabled** — `ss06` breaks the
connected strokes between italic letters, so leaving it off keeps the flowing
cursive look.

Fine-tune with more OpenType tags (`font-feature = <tag>`):

- **Stylistic sets** `ss01` broken `==` · `ss02` broken `<= >=` · `ss04` broken
  `__` · `ss05` thin `\` in escapes · `ss06` break italic strokes *(avoid)* ·
  `ss07`–`ss11` various arrow / `~=` / `≈` ligatures.
- **Character variants** `cv01` special symbols · `cv02` alt `a` · `cv05`
  double-story `g` · `cv61` straight-tail `, ;` · `cv62` open `?` · `cv63`/`cv64`
  `<=` styles · `cv65` handwriting `&` · `cv66` pipe arrows.
- **Italic-only** `cv31`–`cv44` swap individual cursive letters (italic `a`, `f`,
  `k`, `l`, `x`, `y`, `g`, …). Full names: `ghostty +show-config` or the
  [Maple font docs](https://github.com/subframe7536/maple-font).

## Switching fonts (`font`)

Try fonts fast with the **`font`** helper (`font.zsh`, mirrors `theme`): it
rewrites the `font-family*` lines in `ghostty/config` and remembers the choice in
`.active-font`. Ghostty can't reload from the shell, so after switching press
**`Cmd+Shift+,`** (the `reload_config` keybind) to see it.

```sh
font list          # show current + all options
font argon         # a Monaspace cut (keeps Radon italic / Xenon bold)
font jetbrains     # another family (uses its own italic / bold faces)
font next          # cycle to the next one
```

Available: **Monaspace** neon / argon / xenon / radon / krypton, plus
**jetbrains / maple / iosevka / geist / commit**. All are Nerd Fonts — required,
since the prompt and tools rely on Nerd Font glyphs. Add more by editing
`FONT_FAMILIES` in `font.zsh` (and installing the cask).

---

Next: [Troubleshooting →](10-troubleshooting.md)
