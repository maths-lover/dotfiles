[Documentation index](README.md)

# 12. zellij (terminal multiplexer)

zellij is the terminal multiplexer in this setup: persistent sessions, panes,
and tabs, like tmux but with a discoverable UI. Config lives in
`~/.config/zellij/config.kdl`.

> One-page key reference: `zz` (or `bat ~/.config/zellij/CHEATSHEET.md`).

## Mental model

```
session (per project)  ->  tab (context)  ->  pane (terminal)
```

Unlike tmux (one server, many windows), the habit here is ONE SESSION PER
PROJECT, named after the project directory. Sessions persist: detach and the
session keeps running; reattach later (even over SSH). `zellij kill-session
<name>` ends one.

## Locked by default — the one key to learn

This config sets `default_mode "locked"`: every key goes straight to your
shell and zellij ignores you until you press **`Ctrl g`** to unlock. Lock
again with `Ctrl g` when done. While learning you cannot trigger panes/tabs
by accident, and the status bar at the bottom always shows the keys for the
mode you are in — it doubles as the built-in help.

## Modes and keys

Unlock first (`Ctrl g`), then a mode key. Press the same key again (or
`Enter`/`Esc`) to return to normal mode.

| Key | Mode | Essentials inside that mode |
|-----|------|-----------------------------|
| `Ctrl p` | pane | `n` new, `d` down, `r` right, `x` close, `f` fullscreen |
| `Ctrl t` | tab | `n` new, `x` close, `r` rename, `1`..`9` jump |
| `Ctrl n` | resize | arrows/`hjkl` grow & shrink |
| `Ctrl h` | move | move panes around |
| `Ctrl s` | scroll | scrollback + search |
| `Ctrl o` | session | `d` detach, `w` session manager |
| `Ctrl q` | — | quit zellij (any mode) |

Handy keys that work straight from normal mode: `Alt n` new pane, `Alt f`
floating pane, `Alt hjkl`/arrows move focus.

### Detach / reattach

1. `Ctrl g` (unlock), `Ctrl o` (session mode), `d` (detach).
2. Back in the plain shell: `zellij attach <name>` to reattach,
   `zellij list-sessions` to see what is running.

## Project switching: `zj`

`zj` (zsh function, also bound to Ctrl-f) is the jump-between-projects move:

1. fuzzy-pick a directory from zoxide (with an eza tree preview),
2. outside zellij: `zellij attach -c <name>` — attach, creating the session
   rooted at the project if it does not exist,
3. inside zellij: `zellij action switch-session <name>` — switch to the
   project's session, creating it in the background first if missing.

## Aliases

| Alias | Action |
|-------|--------|
| `zz` | view the cheatsheet |

No launch alias needed: use `zj`, or plain `zellij` / `zellij attach -c <name>`.

## Config & theme

Config is `~/.config/zellij/config.kdl`. This repo sets only
`default_mode "locked"` and a custom `ansi` theme that maps zellij's colors to
terminal palette indices 0–15, so the live `theme` light/dark switcher
recolors zellij too (same trick as eza/bat/fzf — see [Themes](08-themes.md)).
Everything else is zellij defaults.

## Remote: work machine runs tmux, not zellij

The daily pattern for the work box (no zellij installed there):

1. Local zellij: one tab per context. Make a tab for work
   (`Ctrl g`, `Ctrl t`, `n`, then `r` to rename it).
2. In that tab: `ssh workbox` (host alias lives in `~/.ssh/config.local`).
3. On the remote: attach the existing tmux setup (tmux-sessionizer / `tmux
   new -A -s main`).
4. **Lock local zellij (`Ctrl g`) and leave it locked.** Locked mode disables
   every zellij shortcut except `Ctrl g` itself, so tmux's `Ctrl b` prefix and
   all its keys pass clean through. Zero collision.

To touch LOCAL zellij mid-work: `Ctrl g` (unlock) -> do the local pane/tab
move -> `Ctrl g` (relock). Remote tmux idles meanwhile and loses nothing.

Why not ssh per local zellij pane: every pane would be a live ssh session — a
network blip kills them all. Remote tmux keeps the session on the server; ssh
is just a viewer. Reconnect, reattach, everything intact. (`ControlMaster` in
`~/.ssh/config` still makes one-off `ssh workbox 'cmd'` from any pane instant.)

Rule of thumb: **command -> plain ssh. session -> remote tmux.**

tmux copy reaches the Mac clipboard via OSC52 (`set -g set-clipboard on` in
remote `~/.tmux.conf`): tmux copy-mode -> ssh -> locked zellij (passes escape
sequences through) -> Ghostty -> macOS clipboard.

## Remote: zellij on both ends (nested zellij)

If the remote DOES have zellij: same locked-outer trick, but remember `Ctrl g`
never reaches the remote — the outer zellij always eats it. So don't lock the
remote instance; if it starts locked, unlock it once via CLI:

```sh
zellij action switch-mode normal
```

Then drive the remote normally; outer-locked gates the input anyway.

## Power moves (beyond the cheatsheet)

- **Swap layouts**: `Alt [` / `Alt ]` cycle tiled -> vertical -> horizontal ->
  stacked without moving panes.
- **Stacked panes**: pane mode `s` — several shells in one frame, strip on top.
- **Scrollback superpowers** (scroll mode, `Ctrl s`): `c` copies the last
  command's output; `e` opens scrollback in `$EDITOR` (nvim); `[` / `]` jump
  between shell prompts; `m` selects the command block at the cursor.
- **Sync tab**: tab mode `s` broadcasts keystrokes to every pane in the tab
  (ssh to N servers, run one command everywhere). Toggle off after.
- **Session manager**: session mode `w` — switch, rename, delete; dead sessions
  can be resurrected (layout re-run).
- **CLI/scripting**: `zellij run --floating --name lazygit -- lazygit`,
  `zellij edit <file>`, `zellij action new-pane --cwd "$PWD"`,
  `zellij action switch-mode locked`. Everything the UI does, the CLI does.

---

Next: [Neovim](11-neovim.md)
