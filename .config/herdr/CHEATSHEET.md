# herdr cheatsheet (this config)

View any time:  hh   (or: bat ~/.config/herdr/CHEATSHEET.md)

herdr is an agent multiplexer: ONE persistent server, a WORKSPACE per project,
TABS for contexts, PANES for terminals. Coding agents (Claude Code, etc.) report
their state in the sidebar. Prefix is Ctrl-b (tmux-style); the whole UI is also
clickable with the mouse.

## Start / leave
| Do | How |
|----|-----|
| Jump to a project (zoxide+fzf -> workspace) | `zj`  (or Ctrl-f) |
| Launch / attach | `herdr`  (alias `hd`) |
| Detach (everything keeps running) | `Ctrl-b q` |
| List workspaces | `hl` |
| Status (client + server) | `hs` |
| Stop the server (ends everything) | `hstop` |

## Prefix mode: press Ctrl-b, then a key

### Workspaces (one per project)
| Key | Action |
|-----|--------|
| `w` | workspace picker |
| `g` | goto / jump |
| `Shift-n` | new workspace |
| `Shift-w` | rename workspace |
| `Shift-d` | close workspace |

### Tabs (contexts within a workspace)
| Key | Action |
|-----|--------|
| `c` | new tab |
| `n` / `p` | next / previous tab |
| `1`..`9` | jump to tab N |
| `Shift-t` | rename tab |
| `Shift-x` | close tab |

### Panes (terminals)
| Key | Action |
|-----|--------|
| `v` | split right |
| `-` | split down |
| `h j k l` | focus left / down / up / right |
| `Shift-h/j/k/l` | swap pane in that direction |
| `Tab` / `Shift-Tab` | cycle panes |
| `z` | zoom (fullscreen) toggle |
| `x` | close pane |
| `r` | resize mode |
| `[` | copy / scrollback mode |
| `e` | edit scrollback in $EDITOR |
| `Shift-p` | rename pane |

### Misc
| Key | Action |
|-----|--------|
| `b` | toggle sidebar |
| `?` | help (all bindings) |
| `s` | settings |
| `Shift-r` | reload config |
| `Alt-g` | pop lazygit in a temp pane (custom) |

## Agent states (sidebar)
working = running  |  blocked = needs you  |  done = finished, unseen  |  idle = seen

## Remote
| Do | How |
|----|-----|
| Persistent session on a server (like tmux) | `ssh host` then `herdr` |
| Thin client (bridges local clipboard + keys) | `herdr --remote host` |

## Config & theme
- Config: `~/.config/herdr/config.toml`  (apply live: `herdr server reload-config`).
- Theme is `terminal`, so it follows the ANSI palette -> the `theme <name>`
  switcher recolors herdr too. Restart the server for [experimental] changes.
- Kitty graphics are on, so inline images work (the xkcd greeting, previews).

## The `zj` layout
Inside herdr, `zj` focuses the project's workspace, or builds a new one with the
coding layout: editor (nvim) on the left, a shell over lazygit on the right.
Outside herdr, `zj` just launches herdr rooted at the chosen project.
