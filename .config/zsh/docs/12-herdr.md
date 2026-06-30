[Documentation index](README.md)

# 12. herdr (agent multiplexer)

herdr replaces zellij in this setup. It is a terminal multiplexer built for
running coding agents (Claude Code, Codex, ...): persistent sessions and panes
like tmux, PLUS it tracks each agent's state in a sidebar. Config lives in
`~/.config/herdr/`.

> One-page key reference: `hh` (or `bat ~/.config/herdr/CHEATSHEET.md`).

## Mental model

```
server  ->  workspace (per project)  ->  tab (context)  ->  pane (terminal)
```

One persistent server holds everything. Unlike zellij (a session per project),
herdr keeps ONE session and gives each project its own WORKSPACE. The sidebar
rolls up agent state per workspace, so you can see which project needs attention.

Sessions persist: detach with `Ctrl-b q` and the server, panes, and agents keep
running; reattach later (even over SSH). `hstop` (`herdr server stop`) ends it.

## Keybindings (prefix = Ctrl-b)

Modal like tmux/vim: press `Ctrl-b`, then an action key. Full list in the
cheatsheet (`hh`); the essentials:

| Key | Action |
|-----|--------|
| `Ctrl-b w` | workspace picker |
| `Ctrl-b Shift-n` | new workspace |
| `Ctrl-b c` | new tab; `n`/`p` next/prev; `1`..`9` jump |
| `Ctrl-b v` / `Ctrl-b -` | split right / down |
| `Ctrl-b h j k l` | focus pane left/down/up/right |
| `Ctrl-b z` | zoom pane; `x` close; `r` resize mode |
| `Ctrl-b [` | copy / scrollback mode |
| `Ctrl-b b` | toggle sidebar; `?` help |
| `Ctrl-b q` | detach |
| `Ctrl-b Alt-g` | pop lazygit in a temp pane (custom) |

The whole UI is also mouse-clickable.

## Project switching: `zj`

`zj` (zsh function, also bound to Ctrl-f) is the jump-between-projects move:

1. fuzzy-pick a directory from zoxide (with an eza tree preview),
2. inside herdr: focus that project's workspace, or build one with the coding
   layout (nvim on the left, a shell over lazygit on the right),
3. outside herdr: launch herdr rooted there.

## Aliases

| Alias | Command |
|-------|---------|
| `hd` | `herdr` (launch / attach) |
| `hl` | `herdr workspace list` |
| `hs` | `herdr status` |
| `hstop` | `herdr server stop` |
| `hh` | view the cheatsheet |

## Config & theme

Config is `~/.config/herdr/config.toml`. This repo sets zsh as the pane shell,
`theme = "terminal"` so herdr follows the `theme` switcher (see
[Themes](08-themes.md)), kitty graphics on for inline images, and a lazygit
binding on `Ctrl-b Alt-g`. Apply changes to a running server with
`herdr server reload-config`; `[experimental]` keys need a full restart.

## Remote

`ssh host` then `herdr` gives a persistent remote session (like tmux). Or
`herdr --remote host` runs a thin local client that bridges your local clipboard
and keybindings to the remote server.

## Agents

herdr detects coding agents in panes and shows `working` / `blocked` / `done` /
`idle` in the sidebar, and can play a sound when one finishes or needs input.

---

Next: [Neovim](11-neovim.md)
