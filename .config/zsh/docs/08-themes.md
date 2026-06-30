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
theme dark          # default dark   (tokyonight)
theme light         # default light  (gruvbox-light)
theme toggle        # flip dark ⇄ light
theme "Rose Pine"   # any Ghostty theme name (quote spaces)
```

Tab-completion is available for the aliases and sub-commands.

## Bundled aliases

| Mode | Aliases |
|------|---------|
| 🌙 dark | `tokyonight` `dracula` `gruvbox` `cyberpunk` `homebrew` `matrix` |
| ☀️ light | `gruvbox-light` `latte` `github-light` `tokyonight-day` |

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
- Inside a multiplexer (`tmux`/`herdr`), OSC sequences may need passthrough to reach the terminal. herdr's `theme = "terminal"` follows the host palette.

---

Next: [Fonts →](09-fonts.md)
