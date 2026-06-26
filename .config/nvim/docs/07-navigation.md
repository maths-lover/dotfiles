[Documentation index](README.md)

# 7. Navigation & search

## fzf-lua (find / grep)

Mirrors the terminal fzf workflow. Colors derive from the active colorscheme, so it
follows the OS theme.

| Key | Action |
|-----|--------|
| `<leader><space>` / `<leader>ff` | find files |
| `<leader>fg` | live grep |
| `<leader>fw` | grep word under cursor |
| `<leader>fb` | buffers |
| `<leader>fr` | recent files |
| `<leader>fh` | help tags |
| `<leader>fk` | keymaps |
| `<leader>fd` | document diagnostics |
| `<leader>fc` | resume last picker |
| `<leader>/` | search lines in current buffer |
| `<leader>gc` | git commits |
| `<leader>gs` | git status |

LSP pickers (`gd`, `gr`, `gI`, `gy`, `<leader>cs`) also use fzf-lua - see
[LSP & languages](05-lsp-and-languages.md).

## oil (file explorer)

Edit the filesystem like a normal buffer (rename/create/delete by editing text,
then `:w`).

| Key | Action |
|-----|--------|
| `-` | open parent directory |
| `<leader>fe` | open oil |
| `q` (in oil) | close |

Hidden files are shown.

## flash (motions)

Jump anywhere on screen by typing a couple of characters.

| Key | Action |
|-----|--------|
| `s` | flash jump (normal/visual/operator) |
| `S` | flash treesitter (select nodes) |
| `r` (operator) | remote flash |

## Treesitter text objects

Select/move by syntax node (in `lua/plugins/treesitter.lua`).

| Key | Selects |
|-----|---------|
| `af` / `if` | a function / inner function |
| `ac` / `ic` | a class / inner class |
| `aa` / `ia` | a parameter / inner parameter |

Movement: `]f` / `[f` next/prev function start; `]a` / `[a` next/prev parameter.
Incremental selection: `<C-space>` to expand, `<bs>` to shrink.

---

Next: [Git](08-git.md)
