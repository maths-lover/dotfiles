[← Documentation index](README.md)

# 7. Prompt (Starship)

Defined in `~/.config/starship.toml`. A **boxed two-line powerline** prompt,
framed with `╭` at the top-left and `╰─❯` on line 2. Line 1 is a row of
connected capsule "pills" split by a `$fill`: **context on the left** (OS,
directory, git) and **toolchains / status / clock on the right**. On a bare TTY
or over SSH it drops to a plain ASCII fallback (see below).

Colours are **palette roles**, so the prompt follows the active Ghostty theme
and the `theme` switcher. Four palettes exist — generic `[palettes.theme-dark]`
/ `[palettes.theme-light]` (ANSI roles, no hex) and GitHub-specific
`[palettes.github-dark]` / `[palettes.github-light]` (Primer hex tokens for
panel/frame) — and the `theme` command flips the active `palette = '...'` line
on every switch (see "Colours" below). The old rose-pine
role *names* are kept (`orange`, `cyan`, `box`, `current_line`, …) but now map to
ANSI. Every glyph is a **Nerd Font** glyph (Ghostty uses MonaspiceNe).

## Line 1 — left side (context)

| Segment | Accent | Meaning |
|---------|--------|---------|
| OS icon | orange | current OS — Apple logo on macOS, distro glyph over SSH/elsewhere |
| directory | green | current directory (truncated to last 2 components — see below); read-only marker when applicable |
| git branch | cyan | current branch |
| git status | yellow | working-tree counts: modified / staged / untracked / stashed / deleted / renamed / conflicted, plus ahead / behind |
| git commit | pink | short commit hash (+ tag) — shown **always** (not just detached) |
| git state | red | in-progress op (rebase / merge / cherry-pick / bisect) with step count |
| **git metrics** | green / red | **added / deleted line counts** — only when the working tree has uncommitted diffs |

## Line 1 — right side (after the `$fill`)

| Segment | Accent | Meaning |
|---------|--------|---------|
| languages | per-lang | toolchain + version — node / .NET / python / java / lua / go / c, only in a matching project |
| cmd duration | orange | last command duration (≥ 500 ms) |
| **jobs** | cyan | number of background jobs (≥ 1) |
| **status** | red | **exit status** — meaning / signal name / code, only on failure (each stage of a failed pipeline) |
| shell | purple | shell indicator |
| clock | purple | `HH:MM` — **disabled by default** (`[time] disabled = true`; set `false` to show) |
| username | yellow | current user (always shown; bold-red as root) |

## Line 2 — prompt character

The bottom of the frame (`╰─`) plus the prompt symbol:

| State | Glyph | Colour |
|-------|-------|--------|
| success | `❯` | green |
| error (last command failed) | `×` | red |

No per-vim-mode sigils are set in this config. To get NORMAL/VISUAL/REPLACE
glyphs, add `vimcmd_symbol` / `vimcmd_visual_symbol` / `vimcmd_replace_symbol` to
`[character]`.

## Directory (truncated to 2)

This layout shows only the **last two path components**:

```toml
[directory]
truncation_length = 2       # last 2 components only
truncation_symbol = ' '     # leading marker
home_symbol       = "󰉌 "    # $HOME icon
```

Known folders get an icon via `[directory.substitutions]` (`Documents`,
`Downloads`, `Music`, `Pictures`, `Develop`/`develop`). **For the full
untruncated path**, set `truncation_length = 0` and add `truncate_to_repo =
false`.

## git metrics vs git status

They don't overlap: `git_status` reports **file** counts (how many files are
modified / staged / untracked / …), while `git_metrics` reports **line** counts
(`+added -deleted`) of the current diff. Metrics stay hidden in a clean repo.

## Always-on commit hash

`[git_commit]` has `only_detached = false`, so the short hash shows on **every**
prompt, not just on a detached HEAD. Set `only_detached = true` to only show it
when detached.

## TTY / SSH fallback

The boxed powerline needs a Nerd Font and colour. On a bare Linux virtual
console (`TERM=linux`) or inside an SSH session, `.zshrc` transparently points
`STARSHIP_CONFIG` at **`~/.config/starship-plain.toml`** instead:

```sh
# .zshrc (excerpt)
if [[ $TERM == linux || $TERM == dumb || -n $SSH_CONNECTION || -n $SSH_TTY ]]; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship-plain.toml"
fi
```

The plain config keeps the same two-line shape and ANSI palette roles but drops
all powerline caps, background panels and Nerd Font glyphs: git status uses
ASCII letters, language chips become short text tags, and the prompt character
is `>`. It still shows the `user@host` + LAN-IP identity so remote sessions are
unmistakable.

## Colours (theme-aware)

Four palettes exist; the `theme` command picks one per switch. Segment body
text (`$path`, `$branch`, …) is unstyled default-fg on `bg:box`, so `box` is
the contrast-critical role everywhere.

`theme-dark` / `theme-light` are **generic ANSI palettes** (no hex) that follow
any Ghostty theme. Light themes invert accent semantics (their `bright-*`
slots are text colours, not panel colours), hence the split:

| role | `theme-dark` | `theme-light` |
|------|--------------|---------------|
| `box` (segment panel) | `bright-black` | `bright-white` |
| `primary` (symbol on accent cap) | `black` | `bright-white` |
| `current_line` (frame lines) | `bright-black` | `bright-black` |
| accents (`green`, `cyan`, …) | `bright-*` | normal slots |

`github-dark` / `github-light` are used for the GitHub terminal themes
specifically. Their palettes have no usable panel/border slots, so panel and
frame come from **GitHub Primer design tokens** (hex) while accent caps stay on
the theme's own ANSI slots — no colour distortion:

| role | `github-dark` | `github-light` |
|------|---------------|----------------|
| `box` (panel) | `#3d444d` (border-default) | `#d1d9e0` (border-default) |
| `primary` (on accent cap) | `#0d1117` (canvas) | `#ffffff` |
| `current_line` | `#6e7681` (border-emphasis) | `#818b98` (border-emphasis) |
| accents | `bright-*` slots | normal slots (white text = Primer button pattern) |

The `theme` zsh function seds the `palette = '...'` line in `starship.toml` on
switch; starship re-reads config on every prompt, so it applies instantly.

Want the fixed rose-pine look instead? set the terminal to it with `theme
rosepine-dawn`, or hard-code hex values in a palette.

## Nerd Font

Every icon (and the powerline separator caps) is a Nerd Font glyph in
**MonaspiceNe Nerd Font Mono** (the Ghostty font — see [Fonts](09-fonts.md)).
Without a Nerd Font they render as boxes — which is why the TTY/SSH fallback
above exists. Note: the cap glyphs are stored as exact bytes; if you hand-edit
them and they vanish, re-inject with `perl -CSD` (see the config header).

---

Next: [Themes →](08-themes.md)
