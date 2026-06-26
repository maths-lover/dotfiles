[← Documentation index](README.md)

# 9. Fonts

**Monaspace Nerd Fonts**, installed via Homebrew:

```ruby
# Brewfile
cask "font-monaspice-nerd-font"
```

The Nerd Font project shortens the Monaspace cut names (Neon→Ne, Argon→Ar,
Krypton→Kr, Radon→Rn, Xenon→Xe). The terminal uses three cuts for visual flair —
configured in `~/.config/ghostty/config`:

| Role | Family | Monaspace cut |
|------|--------|---------------|
| regular | `MonaspiceNe Nerd Font Mono` | Neon (neo-grotesque) |
| italic / bold-italic | `MonaspiceRn Nerd Font Mono` | Radon (cursive — great for comments) |
| bold | `MonaspiceXe Nerd Font Mono` | Xenon (slab serif) |

Enabled font features: `calt`, `liga`, `dlig` (coding ligatures + Monaspace texture
healing), plus `font-thicken` for crispness on dark backgrounds.

> The **Mono** variant is used so Nerd Font icons occupy a single cell — correct for
> a terminal. To verify what's installed:
> `ghostty +list-fonts | grep Monaspice`

## Using a different font

Edit the `font-family*` lines in `ghostty/config`, then reload with `Cmd+Shift+,`.
Any Nerd Font works; the prompt and tools rely on Nerd Font glyphs, so keep a
Nerd-Font-patched family.

---

Next: [Troubleshooting →](10-troubleshooting.md)
