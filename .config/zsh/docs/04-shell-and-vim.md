[← Documentation index](README.md)

# 4. Shell & vim mode

## History

Stored at `~/.local/state/zsh/history`, 100,000 entries.

- **Shared** across live sessions, written as you go
- **Deduped** (older duplicates dropped) and **timestamped**
- A command typed with a **leading space** is not recorded

## Options

| Option | Effect |
|--------|--------|
| `AUTO_CD` | type a path (no `cd`) to change into it |
| `AUTO_PUSHD` | every `cd` pushes the dir stack — see `dirs -v`, `cd -<Tab>` |
| `EXTENDED_GLOB` | `#`, `~`, `^` glob operators |
| `GLOB_DOTS` | globs match dotfiles |
| `INTERACTIVE_COMMENTS` | `#` comments allowed at the prompt |

## Completion

- Cached `compinit` (re-audited once per 24h) for fast startup
- **Case-insensitive + fuzzy** matching
- **fzf-tab**: pressing `<Tab>` opens an fzf menu with previews — directory trees
  via `eza`, file contents via `bat`

## Plugins (load order matters)

`fzf-tab` → `zsh-autosuggestions` → `zsh-syntax-highlighting` (must be last).

---

## Vim mode

The line editor runs in **vi mode** (`bindkey -v`) with `KEYTIMEOUT=1` for an
instant `ESC`. Two cues show the mode:

| Cue | Insert | Normal |
|-----|--------|--------|
| Prompt symbol | `λ` | `Λ` |
| Cursor shape | beam | block |

### Normal mode (`vicmd`)

| Key | Action |
|-----|--------|
| `k` / `j` | history previous / next (prefix-aware) |
| `/` `?` `n` | search history |
| `v` | edit the current command line in **neovim** |
| `ci(` `di"` `ya{` `va[` … | text objects — brackets & quotes |
| `cs"'` | change surrounding `"` → `'` |
| `ds(` | delete surrounding `()` |
| `ys$"` | surround to end-of-line with `"` |
| `S` (visual) | surround the selection |

### Insert mode (`viins`) — handy emacs keys kept

| Key | Action |
|-----|--------|
| `Ctrl-A` / `Ctrl-E` | start / end of line |
| `Ctrl-W` | delete word backward |
| `Ctrl-U` / `Ctrl-K` | kill to start / end of line |
| `Ctrl-P` / `Ctrl-N` / `↑` / `↓` | history (prefix search) |
| `Ctrl-X Ctrl-E` | edit line in neovim |
| `Home` / `End` / `Ctrl-←` / `Ctrl-→` | navigation |
| `Ctrl-Y` | yank |

### fzf widgets (both modes)

| Key | Action |
|-----|--------|
| `Tab` | fzf-tab completion menu |
| `Ctrl-R` | fuzzy history search |
| `Ctrl-T` | fuzzy file picker (inserts path) |
| `Alt-C` | fuzzy `cd` into a subdirectory |

> The mode indicator (`λ`/`Λ`) is driven by Starship; the cursor shape by a
> `zle-keymap-select` hook that chains cleanly with Starship's own hook.

---

Next: [Aliases & functions →](05-aliases-and-functions.md)
