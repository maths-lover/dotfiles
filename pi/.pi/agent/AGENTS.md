# Global agent instructions

## Shell tool preferences

Prefer modern CLI tools over the classic ones. Use the modern tool when it is
installed; fall back to the classic equivalent only when the modern one is
missing.

| Task                   | Prefer         | Instead of       | Example                |
| ---------------------- | -------------- | ---------------- | ---------------------- |
| Search file contents   | `rg` (ripgrep) | `grep`, `egrep`  | `rg -n 'pattern' src/` |
| Find files/dirs        | `fd`           | `find`           | `fd -e ts cockpit`     |
| View a file for humans | `bat`          | `cat`            | `bat -pp file`         |
| JSON                   | `jq`           | manual parsing   | `jq '.key' file.json`  |
| YAML / XML / TOML      | `yq`           | manual parsing   | `yq '.key' file.yaml`  |
| Fuzzy pick             | `fzf`          | manual selection | `... \| fzf`           |

Plain `cat`/`ls` inside pipes or scripts is fine; the preferences above are
about the tool I reach for when doing the work myself.

Skip tools that emit icons, colors, or unicode bars/box-drawing in their output
(`eza --icons`, `dust`, `procs`, `delta`) — the decoration is wasted tokens when
I parse it. When a useful tool colorizes by default, force plain output
(`--color=never`, `bat -pp`). `rg`/`fd`/`jq`/`yq` are plain already.

### IMPORTANT: don't let the swap hide files

`rg` and `fd` **skip `.gitignore`d files and hidden dot-files by default** — the
classic `grep -r` / `find` do not. So a naive swap can silently miss matches
(e.g. inside `node_modules/`, `dist/`, or dotfiles). When results might live in
ignored/hidden paths, opt back in explicitly:

- `rg`: add `-uu` (don't respect ignore + search hidden), or `-. ` / `--hidden`
  and `--no-ignore` as needed. Use `rg -uu` when searching vendored trees.
- `fd`: add `-H` (hidden) and `-I` (no ignore), or `-u` (= both), e.g.
  `fd -HI node_modules`.

Also remember the semantic differences: `rg` is recursive by default; `fd`
matches with regex/globs (not literal substrings of a full path) and prints
paths relative to the search root.
