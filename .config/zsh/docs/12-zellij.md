[Documentation index](README.md)

# 12. Zellij (sessions & multiplexing)

Zellij is the terminal multiplexer that makes the shell feel like a native part of
the OS: persistent sessions, saved project layouts, and instant project switching.
It is the equivalent of "Kitty sessions" in this setup. Config lives in
`~/.config/zellij/`.

> One-page key reference: `~/.config/zellij/CHEATSHEET.md`
> (view with `bat ~/.config/zellij/CHEATSHEET.md`).

## Mental model

```
session  ->  tabs  ->  panes
```

Sessions persist: close the terminal and `zellij attach` brings the session back
(also works over SSH). Serialization is on, so even exited sessions can be
resurrected from the session manager.

## Keybindings (zellij defaults)

Modal, like vim. `Ctrl <key>` enters a mode; then press the action key.

| Key | Mode / action |
|-----|---------------|
| `Ctrl p` | pane mode (`n` new, `h/j/k/l` focus, `x` close, `f` fullscreen, `w` floating) |
| `Ctrl t` | tab mode (`n` new, `h/l` switch, `r` rename, `x` close) |
| `Ctrl n` | resize mode |
| `Ctrl s` | scroll / search (search the scrollback) |
| `Ctrl o` | session mode; then `w` opens the session manager (fuzzy switch/create), `d` detaches |
| `Ctrl g` | lock mode - passes every key straight to the app (use while in nvim) |
| `Ctrl q` | quit |
| `Alt n` | new pane (no mode) |
| `Alt h/j/k/l` | move focus (no mode) |
| `Alt +` / `Alt -` | resize focused pane |

`Alt`-based navigation means it does not clash with Neovim's `Ctrl-h/j/k/l` window
movement - both coexist.

## Project switching: `zj` (the core workflow)

`zj` (a zsh function) is the "jump between projects" move:

1. fuzzy-pick a directory from your zoxide history (with an `eza` tree preview),
2. attach to that project's zellij session if it exists, otherwise create it
   running the `coding` layout, with panes opened in that directory.

```sh
zj            # run it, or press Ctrl-f at the prompt
```

Inside zellij, switch sessions with `Ctrl o` then `w` (the built-in manager).

## The `coding` layout

`~/.config/zellij/layouts/coding.kdl` defines a project environment: a large
editor pane (nvim, opens the project via oil) on the left, and a right column with
a shell over lazygit. Launched automatically by `zj` for new sessions.

Add your own layouts as `~/.config/zellij/layouts/<name>.kdl` and launch with
`zellij --layout <name>`.

## Aliases

| Alias | Command |
|-------|---------|
| `zjl` | list sessions |
| `zja` | attach |
| `zjk` | kill a session |
| `zjka` | kill all sessions |

## Theme & aesthetics (matched to Neovim)

A custom `terminal` theme in `config.kdl` maps to the terminal's 16 ANSI colors, so
zellij follows the `theme` switcher (see [Themes](08-themes.md)) just like fzf, bat,
and eza. Clipboard yanks use `pbcopy` (macOS).

The chrome is tuned to match the Neovim UI:
- `pane_frames` with `rounded_corners` - mirrors nvim's rounded window/float borders.
- `simplified_ui true` - flat bars (no powerline arrows), matching the flat lualine.
- `default_layout "compact"` - a single slim bar, like nvim's one statusline (the
  `coding` layout used by `zj` carries the same compact bar).

So across the terminal, zellij, and Neovim you get one consistent look: rounded
borders, flat themed bars, and colors that all follow the active `theme`.

## Optional: auto-start

To always land in a zellij session when you open a terminal, add to `local.zsh`:

```sh
if [[ -z "$ZELLIJ" && -o interactive ]]; then
  zellij attach -c main
fi
```

Left off by default so plain shells stay plain.

---

Next: [Neovim](11-neovim.md)
