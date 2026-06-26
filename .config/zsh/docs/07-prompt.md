[← Documentation index](README.md)

# 7. Prompt (Starship HUD)

Defined in `~/.config/starship.toml`. No user/host — just signal.

```
╭─ 󰚌  ~/dev/project ⇢  main +12 -3 !+?   20.11.0  󰏗 v2.4.1     󰜎1  󱎫2s  󰍛47%   03:22:27
╰─λ
```

## Line 1 — context & intel (left)

| Segment | Meaning |
|---------|---------|
| `󰚌` | skull sigil — the prompt's signature |
| ` ~/dev/project` | current directory (truncates to repo root); `` = read-only |
| `⇢  main` | git branch |
| `+12 -3` | diff metrics — lines added / deleted (each hidden when zero) |
| `!+?` | git status — `!`modified `+`staged `?`untracked `»`renamed `✘`deleted `⇡⇣`ahead/behind |
| ` 20.11.0` | toolchain version (node/python/rust/go/java/c/docker) — only when present |
| `󰏗 v2.4.1` | the project's own package version (package.json / Cargo.toml / …) |

## Right HUD (live)

| Segment | Meaning |
|---------|---------|
| `󰜎1` | background jobs |
| `󱎫2s` | last command duration |
| `󰍛47%` | RAM usage — **color-shifts** green → amber → red |
| `03:22:27` | clock |

## Line 2 — prompt

| Segment | Meaning |
|---------|---------|
| `[✘ N]` | exit-code badge — appears **only on failure** (with signal names) |
| `λ` / `Λ` | prompt symbol — `λ` insert (green ok / red error), `Λ` normal mode |

## How the RAM gauge works

Starship's `memory_usage` has a single static color, so the gauge is built from
**three `custom.ram_*` modules** (green / amber / red), each gated by a range. The
value is computed once per prompt by a `precmd` hook in `.zshrc`:

```sh
_starship_ram_pct()   # active+wired+compressed ÷ total, via vm_stat (~2ms)
                      # exports STARSHIP_RAM_PCT for the custom modules to read
```

Thresholds (edit in `starship.toml` → `custom.ram_*` `when =`): green `<60`,
amber `60–84`, red `≥85`.

## Theme-awareness

All prompt colors are **ANSI palette names** (not hex), so the prompt automatically
follows the active terminal theme — see [Themes](08-themes.md).

---

Next: [Themes →](08-themes.md)
