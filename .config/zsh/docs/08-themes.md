[← Documentation index](README.md)

# 8. Themes

## How it works

Everything — Starship, fzf, bat, eza — is configured with **ANSI palette colors**,
so changing the terminal's 16-color palette re-themes the whole stack at once. The
`theme` command (in `theme.zsh`):

1. Recolors the **current** window instantly via **OSC escape sequences**.
2. Persists the choice to `~/.config/ghostty/config` so **new windows match**.
3. Records the current theme in `~/.config/zsh/.active-theme`.

Theme definitions are read straight from Ghostty's bundled theme files, so any of
its 200+ themes works.

## Usage

```sh
theme               # list themes + show current
theme dracula       # switch (live, no reload needed)
theme gruvbox-light # a light scheme
theme dark          # default dark   (github-dark)
theme light         # default light  (github-light)
theme toggle        # flip dark ⇄ light
theme "Rose Pine"   # any Ghostty theme name (quote spaces)
```

Tab-completion is available for the aliases and sub-commands.

## Bundled aliases

| Mode | Aliases |
|------|---------|
| 🌙 dark | `github-dark` `tokyonight` `dracula` `gruvbox` `cyberpunk` `homebrew` `matrix` |
| ☀️ light | `github-light` `gruvbox-light` `latte` `tokyonight-day` |

(`homebrew` and `matrix` are the bright-green hacker looks.)

## Changing defaults

`theme dark` / `theme light` / `theme toggle` use these — override in `local.zsh`:

```sh
export THEME_DEFAULT_DARK=dracula
export THEME_DEFAULT_LIGHT=latte
```

Add your own alias by editing `THEME_ALIASES` in `theme.zsh`.

## Notes

- Live switching recolors the **current** window only; other open windows update
  when they next launch (they read the persisted Ghostty config).
- zellij renders its own UI, so OSC sequences never reach it directly; instead its custom theme in `config.kdl` maps colors to ANSI palette indices 0-15, so zellij follows the host palette (and this switcher) automatically.
- starship can't follow light/dark with one fixed palette (light themes invert `bright-*` semantics), so it ships four palettes in `starship.toml`: generic `theme-dark`/`theme-light` (ANSI roles) plus `github-dark`/`github-light` (Primer hex tokens for panel/frame, accents stay on the theme's own slots). The `theme` command picks the right one on every switch; applies on the next prompt draw.

---

Next: [Fonts →](09-fonts.md)
