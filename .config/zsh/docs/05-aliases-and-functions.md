[← Documentation index](README.md)

# 5. Aliases & functions

Defined in `aliases.zsh` and `functions.zsh`.

## Aliases

### Listing (eza)
| Alias | Command |
|-------|---------|
| `ls` | `eza --group-directories-first --icons` |
| `l` | `eza -lh … --git` (long) |
| `ll` | `eza -lah … --git` (long, all, incl. hidden) |
| `la` | `eza -a` (all) |
| `lt` / `lt3` | tree, depth 2 / depth 3 |
| `tree` | `eza --tree` |

### Viewing (bat)
| Alias | Command |
|-------|---------|
| `cat` | `bat --paging=never` |
| `catp` | `bat --paging=never --style=plain` (no line numbers/borders) |

> `cat` stays script-safe — bat behaves like plain cat when piped. Bypass any alias
> with a leading backslash (`\cat`) or `command cat`.

### Editor (neovim)
| Alias | Command |
|-------|---------|
| `vim` `vi` `v` | `nvim` |
| `vimdiff` | `nvim -d` |

### Git
| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs` | `git status -sb` |
| `ga` / `gaa` | `git add` / `git add --all` |
| `gc` / `gcm` / `gca` | commit / commit -m / commit --amend |
| `gco` / `gsw` / `gb` | checkout / switch / branch |
| `gd` / `gds` | diff / diff --staged |
| `gp` / `gpl` / `gf` | push / pull / fetch --all --prune |
| `gl` / `gla` | log graph (current / all) |
| `lg` | lazygit |

### Misc & safety
| Alias | Command |
|-------|---------|
| `top` | btop |
| `cls` | clear |
| `reload` | `exec zsh` |
| `zshrc` / `zshreload` | edit / re-source `.zshrc` |
| `path` | print `$PATH`, one per line |
| `ip` / `myip` | LAN IP / public IP |
| `ports` | listening TCP ports (`lsof`) |
| `df` | `df -h` |
| `cp` `mv` `rm` | interactive + verbose (`-iv`) |
| `mkdir` | `mkdir -pv` |

## Functions

| Function | Usage | Does |
|----------|-------|------|
| `mkcd` | `mkcd path/new` | `mkdir -p` then `cd` into it |
| `up` | `up 3` | go up N directories |
| `extract` | `extract file.tar.gz` | universal archive extractor |
| `ff` | `ff <pat> [path]` | list files by name (fd); add a path to search outside cwd |
| `fdir` | `fdir <pat> [path]` | list directories by name (fd) |
| `frg` | `frg [query]` | live content search (rg+fzf), open the hit in neovim at the line |
| `fcd` | `fcd` | fuzzy-pick a subdir (fd+fzf, tree preview) and cd |
| `fe` | `fe` | fuzzy-pick a file, open in neovim |
| `fkill` | `fkill [signal]` | fuzzy-pick process(es) and kill |
| `fbr` | `fbr` | fuzzy-checkout a git branch (local or remote) |
| `gclone` | `gclone <url>` | clone a repo then cd into it |
| `zj` | `zj` (or Ctrl-f) | fuzzy project switcher -> herdr workspace |
| `nvp` | `nvp` | fuzzy-pick a project, open it in its own Neovide window |

## Scratchpad (`scratch`)

`scratch` is a script in `~/.local/bin` (not a shell function). It opens quick,
persistent note files in Neovide — or in nvim inside a throwaway ghostty window
(`-t`). Notes live in `~/Documents/ScratchpadNotes` (untracked) and stick around;
reopen to continue where you left off.

| Invocation | Does |
|------------|------|
| `scratch` | open the default pad `scratch.txt` (Neovide) |
| `scratch <name>` | open/create `<name>` (`.txt` unless you give an extension) |
| `scratch ideas.md` | name a `*.md` file for markdown highlighting |
| `scratch -p` | fuzzy-pick an existing pad (fzf, bat preview) |
| `scratch -t [name]` | open in nvim in a new ghostty window (self-closes on `:q`) |
| `scratch -l` | list existing pads |

Autosave writes on focus-loss, buffer-switch and quit; a manual `:w` still works.
The Neovide pad opens as a small, non-intrusive window (`--grid`, default `96x28`)
and won't overwrite your normal `nvp` window size. Tune via env: `$SCRATCH_DIR`,
`$SCRATCH_EXT` (e.g. `md`), `$SCRATCH_DEFAULT`, `$SCRATCH_AUTOSAVE=0`,
`$SCRATCH_GRID` (e.g. `110x32` bigger, `80x24` smaller).

**Global hotkey (macOS).** Shortcuts.app → new shortcut *Open Scratchpad* → add a
**Run Shell Script** action with body `$HOME/.local/bin/scratch` → open the ⓘ panel
and assign a keyboard shortcut (e.g. `⌘⇧Space`). The script hardcodes
`/opt/homebrew/bin` fallbacks, so it launches even under Shortcuts' minimal PATH.
The hotkey opens the default pad; use `-p` from a terminal to pick another.
(Alt: Script Editor / Automator Quick Action running
`do shell script "$HOME/.local/bin/scratch >/dev/null 2>&1 &"`, bound in
System Settings → Keyboard → Shortcuts.)

**Scratchpad vs clipboard.** The clipboard is a single slot for text you *already
have* (a manager like Maccy keeps a time-limited history, but old copies age out).
The scratchpad is for *composing new* text and keeping it — persistent named files
you can reopen and search. Different jobs; use both.

---

Next: [Navigation →](06-navigation.md)
