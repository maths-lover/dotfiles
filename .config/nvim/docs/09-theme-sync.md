[Documentation index](README.md)

# 9. Theme sync

Neovim follows the OS colorscheme set by the shell `theme` command, so the terminal
and the editor always match. Implemented in `lua/config/theme.lua`.

## How it works

1. The shell `theme` command writes the active theme name to
   `~/.config/zsh/.active-theme`.
2. On startup, Neovim reads that file and picks a matching colorscheme + background
   (light/dark).
3. It re-syncs automatically on `FocusGained` and via a file-watch on the state
   file, so changing the terminal theme updates a running Neovim too.

## Mapping

`lua/config/theme.lua` maps theme names to installed colorschemes. Examples:

| OS theme | Neovim colorscheme | bg |
|----------|--------------------|----|
| tokyonight | tokyonight-night | dark |
| tokyonight-day | tokyonight-day | light |
| dracula | dracula | dark |
| gruvbox / gruvbox-light | gruvbox | dark / light |
| latte | catppuccin-latte | light |
| rose-pine / rose-pine-dawn | rose-pine / rose-pine-dawn | dark / light |

The resolver is family-aware: it also handles full Ghostty theme names (for
example "Rose Pine Dawn", "Catppuccin Mocha") and infers light vs dark from the
name. Terminal-only neon themes (cyberpunk, homebrew, matrix) fall back to a rich
dark scheme.

## Commands

| Command | Action |
|---------|--------|
| `:ThemeSync` | force a re-read of the active theme and re-apply |

## Customizing

- Add or change mappings in the `MAP` table in `lua/config/theme.lua`.
- Install a new colorscheme in `lua/plugins/colorschemes.lua` (high priority), then
  reference it in the map.
- lualine uses `theme = auto`, so the statusline follows along automatically.

---

Next: [Neovide](10-neovide.md)
