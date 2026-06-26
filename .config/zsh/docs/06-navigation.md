[← Documentation index](README.md)

# 6. Navigation (zoxide + fzf)

`z` learns directories you visit (frecency = frequency + recency) and jumps to them.

## Jump to a known directory

```sh
z foo            # jump to the best-ranked match for "foo"
z server api     # multiple terms, matched in path order → .../server/api
z serv api       # partial terms work too
```

## Pick among multiple matches

```sh
zi foo           # interactive fzf picker of all matches, ranked
z foo<Tab>       # same interactive picker, inline
zi               # browse the entire database
```

## Go somewhere new (not in the database yet)

`z` only knows places you've been. For a new directory, use a finder — the act of
`cd`-ing there adds it to zoxide for next time.

| Method | Best for |
|--------|----------|
| `Alt-C` | fuzzy-cd into a subdirectory of the current dir |
| `cd **<Tab>` | fzf path completion from anywhere |
| `fcd` | same as Alt-C, as a command |
| type the path | `AUTO_CD` is on — `~/dev/foo` works without `cd` |

## Curate the database

```sh
zoxide query -l foo      # list matches
zoxide query -ls foo     # list with frecency scores
zoxide remove <path>     # drop a stale/wrong entry
```

**Rule of thumb:** `z one-word` for the obvious place → add a word (`z foo bar`) when
it guesses wrong → `zi foo` when you want to eyeball the choices.

---

Next: [Prompt →](07-prompt.md)
