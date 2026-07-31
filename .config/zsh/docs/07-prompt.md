[← Documentation index](README.md)

# 7. Prompt (Starship)

Defined in `~/.config/starship.toml`. A tidy two-line prompt: the **full path**
plus Nerd Font icons on line 1, a quiet clock on the right, and the prompt
character on line 2. Locally it stays minimal; over SSH it grows a
`user@host` + LAN-IP block so remote sessions are unmistakable.

```
local    ~/dev/project   main !2 +12 -3    1.24             14:22
ssh     me@server 10.0.0.9  ~/src   main ...
        
```

## Line 1 - context (left)

| Segment | Meaning |
|---------|---------|
| `me@server 10.0.0.9` | **SSH only** - user@host + LAN IP; hidden locally (as root the username shows bold red) |
| ` ~/dev/project` | current directory - the **entire path**, never truncated; `󰌾` = read-only |
| ` main` | git branch |
| `(a1b2c3d)` | commit hash (+ tag) - **only on a detached HEAD** |
| `!2 +1 ?3` | git status: `!`modified `+`staged `?`untracked `*`stashed `x`deleted `»`renamed `=`conflicted |
| `1 2` | commits ahead / behind the remote |
| `+12 -3` | git metrics - lines added (green) / deleted (red) since HEAD |
| `rebase 1/3` | in-progress git op (rebase / merge / cherry-pick / bisect) with step count |
| ` 1.24` | toolchain version - go/rust/python/node/zig/java/c/lua/ruby/php, only in a matching project (icon coloured, version muted) |
| `` | direnv active (an `.envrc` is loaded) |
| ` name` | running inside a container |
| ` ctx` / `󱃾 ctx` | docker / kubernetes context - only when relevant |
| `` | sudo credentials currently cached |
| `󰍛 82%` | memory usage - **only when RAM > 75%** |
| ` 2s` | last command duration (shown when >= 2s) |
| ` 1` | background jobs |
| ` INT` / ` NOTFOUND` | exit status - signal name / meaning, **only on failure**; a failed pipeline lists each stage |

## Right side

| Segment | Meaning |
|---------|---------|
| ` 14:22` | clock (HH:MM) |

## Line 2 - prompt character (per vim mode)

| Mode | Glyph | Colour |
|------|-------|--------|
| INSERT | `` | green (ok) / red (last command failed) |
| NORMAL | `` | magenta |
| VISUAL | `` | yellow |
| REPLACE | `` | red (best-effort; zsh has no distinct replace keymap, so it usually falls back to NORMAL) |

Driven by starship's own zsh keymap hook (chains cleanly with the cursor-shape hook).

## Showing the full path

The directory module is set to show everything:

```toml
[directory]
truncation_length = 0      # 0 = do not truncate
truncate_to_repo  = false  # do not clip to the git repo root
truncation_symbol = ""     # no leading .../
home_symbol       = "~"    # $HOME shows as ~
```

To shorten later, raise `truncation_length` (e.g. `3`) or set
`truncate_to_repo = true` (path starts at the repo root).

## Identity block (SSH only)

`username`, `hostname` and `localip` are all `ssh_only`, so locally the line
starts at the directory. Over SSH you get `user@host ip `; as **root** the
username also shows (bold red) even locally, as a safety cue.

## Nerd Font

Every icon is a Nerd Font glyph, verified present in **MonaspiceNe Nerd Font**
(the Ghostty font - see [Fonts](09-fonts.md)). Language/module glyphs come from
`starship preset nerd-font-symbols`; without a Nerd Font they render as boxes.

## Theme-awareness

All prompt colours are **ANSI palette roles** in `[palettes.theme]` (never hex),
so the prompt automatically follows the active terminal theme - see
[Themes](08-themes.md).

---

Next: [Themes →](08-themes.md)
