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
| `zj` | `zj` (or Ctrl-f) | fuzzy project switcher -> zellij session |

---

Next: [Navigation →](06-navigation.md)
