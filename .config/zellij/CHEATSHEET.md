# zellij cheatsheet

Config: `~/.config/zellij/config.kdl` · print this file: `zz` · full docs: <https://zellij.dev/documentation>

## The one key to learn

**`Ctrl g`** — toggle locked/normal mode.

This config starts **locked**: every key goes straight to your shell, zellij
ignores you. Unlock with `Ctrl g` first, then the keys below work. Lock again
with `Ctrl g` when done. The status bar at the bottom always shows the keys
for the mode you are in — it is the built-in help.

## Modes (unlock first, then press)

| Key      | Mode   | What it controls                      |
|----------|--------|---------------------------------------|
| `Ctrl p` | pane   | split, close, fullscreen panes        |
| `Ctrl t` | tab    | new, close, rename, jump between tabs |
| `Ctrl n` | resize | grow/shrink the focused pane          |
| `Ctrl h` | move   | move panes around                     |
| `Ctrl s` | scroll | scrollback, search                    |
| `Ctrl o` | session| detach, switch sessions               |
| `Ctrl q` | —      | quit zellij (works from any mode)     |

Press the same `Ctrl <letter>` again (or `Enter`/`Esc`) to drop back to normal
mode.

## Everyday keys (normal mode, after `Ctrl g`)

### Anywhere
| Key        | Action                          |
|------------|---------------------------------|
| `Alt n`    | new pane (auto-split)           |
| `Alt f`    | toggle floating pane            |
| `Alt h j k l` / arrows | move focus between panes |
| `Alt [` / `Alt ]` | cycle swap layouts (tiled/vertical/stacked) |
| `Alt -` / `Alt =` | shrink / grow focused pane       |

### Pane mode (`Ctrl p`)
| Key | Action                        |
|-----|-------------------------------|
| `n` | new pane                      |
| `d` | new pane below                |
| `r` | new pane right                |
| `x` | close focused pane            |
| `f` | fullscreen toggle             |
| `w` | floating toggle               |
| `c` | rename pane                   |

### Tab mode (`Ctrl t`)
| Key     | Action                     |
|---------|----------------------------|
| `n`     | new tab                    |
| `x`     | close tab                  |
| `r`     | rename tab                 |
| `h`/`l` | previous / next tab        |
| `1`..`9`| jump to tab number         |
| `s`     | sync tab (broadcast keys to all panes!)   |

### Scroll mode (`Ctrl s`)
| Key | Action                                  |
|-----|-----------------------------------------|
| `s` | search scrollback                       |
| `c` | copy last command's output              |
| `e` | open scrollback in `$EDITOR` (nvim)     |
| `[` / `]` | jump between shell prompts          |
| `m` | select command block at cursor          |
| `d` / `u` | half-page down / up                   |

### Session mode (`Ctrl o`)
| Key | Action                          |
|-----|---------------------------------|
| `d` | detach (leave session running)  |
| `w` | session manager (pick session)  |

## CLI

| Command                        | Action                              |
|--------------------------------|-------------------------------------|
| `zellij`                       | new session (random name)           |
| `zellij attach -c <name>`      | attach to session, create if new    |
| `zellij list-sessions`         | list running sessions               |
| `zellij kill-session <name>`   | stop a session                      |
| `zellij delete-session <name>` | delete a dead session               |
| `zellij run --floating -- <cmd>` | run cmd in a floating pane      |
| `zellij edit <file>`           | open file in an editor pane         |
| `zellij action switch-mode locked` | lock/unlock from the shell    |

## This setup

- **`zj`** (or `Ctrl f` outside zellij): fuzzy-pick a project, jump to its
  zellij session. One session per project, named after the directory.
  Outside zellij it attach-creates; inside zellij it switches sessions.
- **`zz`**: print this cheatsheet.
- Locked-by-default + theme follows the terminal's ANSI palette, so the
  `theme` light/dark switcher recolors zellij too.

## Common first session

```sh
zj                       # pick a project -> you land in its session
Ctrl g                   # unlock
Alt n                    # split a pane
Ctrl g                   # lock again, keys back to shell
# ... later:
Ctrl g, Ctrl o, d        # unlock, session mode, detach
zellij attach <name>     # come back
```

## Remote work machine (tmux there, zellij here)

1. Local zellij tab for work: `Ctrl g`, `Ctrl t`, `n`, `r` -> name it.
2. `ssh workbox` (host alias in `~/.ssh/config.local`).
3. Attach remote tmux (`tmux new -A -s main` / tmux-sessionizer).
4. **Lock local zellij (`Ctrl g`) and leave it locked** — tmux's `Ctrl b`
   and all its keys pass straight through. Only `Ctrl g` stays local.
5. Need local zellij mid-work: `Ctrl g` -> local move -> `Ctrl g` back.

Why not ssh-per-pane: network blip kills every pane. Remote tmux keeps the
session on the server; ssh is just a viewer. Rule: command -> plain ssh,
session -> remote tmux.

Remote zellij (if it ever has zellij): same locked-outer trick, but unlock
the remote once via `zellij action switch-mode normal` — `Ctrl g` never
reaches it.
