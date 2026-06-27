# Zellij cheatsheet (this config)

View any time:  bat ~/.config/zellij/CHEATSHEET.md

## Start / leave
| Do | Keys |
|----|------|
| Jump to a project (zoxide + fzf -> session) | `zj`  (or `Ctrl-f` at the shell) |
| Detach (leave it running) | `Ctrl o` then `d` |
| Re-attach | `zja <name>`  /  `zellij attach` |
| List sessions | `zjl` |
| Quit zellij | `Ctrl q` |
| Lock (pass all keys to nvim) | `Ctrl g`  (press again to unlock) |

## Modes: press Ctrl+key, act, then Esc
The bottom status bar shows the current mode's keys.

| Enter mode | Key |
|------------|-----|
| pane | `Ctrl p` |
| tab | `Ctrl t` |
| resize | `Ctrl n` |
| scroll / search | `Ctrl s` |
| session | `Ctrl o` |
| move pane | `Ctrl h` |

## Panes  (`Ctrl p`, then)
| Key | Action |
|-----|--------|
| `n` | new pane |
| `r` / `d` | new pane right / down |
| `h j k l` | move focus (or arrows) |
| `x` | close pane |
| `f` | fullscreen toggle |
| `w` | toggle floating panes (show/hide the floating layer) |
| `e` | send focused pane to floating (or back to tiled) |
| `i` | pin / unpin a floating pane (stays on top, always visible) |
| `z` | hide/show pane frames |
| `c` | rename pane |

Floating workflow: `Alt f` (or `Ctrl p w`) shows the floating layer; `Ctrl p e`
floats the current pane; `Ctrl p i` pins it so it stays visible over the others.

## Tabs  (`Ctrl t`, then)
| Key | Action |
|-----|--------|
| `n` | new tab |
| `h` / `l` | previous / next tab |
| `1`..`9` | jump to tab N |
| `r` | rename tab |
| `x` | close tab |
| `b` | break current pane into its own tab |

## Resize  (`Ctrl n`, then)
| Key | Action |
|-----|--------|
| `h j k l` | grow toward that side |
| `+` / `-` | bigger / smaller |
| `H J K L` | shrink that side |

## Session  (`Ctrl o`, then)
| Key | Action |
|-----|--------|
| `w` | session manager (switch / create) |
| `d` | detach |
| `c` | configuration UI |
| `l` | layout manager |

## Scroll / search  (`Ctrl s`, then)
| Key | Action |
|-----|--------|
| `j` / `k` | scroll down / up |
| `s` | search the output |
| `e` | open the scrollback in nvim |

## Quick keys - no mode needed
| Key | Action |
|-----|--------|
| `Alt n` | new pane |
| `Alt h j k l` | move focus (jumps tabs at the edges) |
| `Alt +` / `Alt -` | resize focused pane |
| `Alt f` | floating panes toggle |
| `Alt [` / `Alt ]` | cycle layout presets |

## This config's extras
- Theme follows the terminal palette, so it tracks the `theme` switcher.
- Mouse-select copies to the macOS clipboard (pbcopy).
- Sessions persist - `Ctrl o` then `w` can resurrect old ones.
- `Ctrl b` enters a tmux-style mode (ignore unless you know tmux).

## The `coding` layout (what `zj` opens)
nvim (left, ~72%) + a shell and lazygit stacked on the right, all in the project dir.

Full guide: ~/.config/zsh/docs/12-zellij.md
