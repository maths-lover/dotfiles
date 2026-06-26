[Documentation index](README.md)

# 3. Keymaps

Leader is `Space`, local leader is `\`. General keymaps live in
`lua/config/keymaps.lua`; plugin keymaps live with their plugin spec (cross-
referenced below). Press `<leader>?` for buffer-local keymaps via which-key.

## General

| Key | Action |
|-----|--------|
| `<Esc>` | clear search highlight |
| `<leader>w` | write |
| `<leader>q` | quit |
| `<leader>Q` | quit all (force) |

## Windows

| Key | Action |
|-----|--------|
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | move to left / down / up / right window |
| `<C-Up>` `<C-Down>` | grow / shrink height |
| `<C-Left>` `<C-Right>` | shrink / grow width |
| `<leader>sv` | split vertical |
| `<leader>sh` | split horizontal |
| `<leader>sc` | close split |

## Buffers

| Key | Action |
|-----|--------|
| `<S-l>` | next buffer |
| `<S-h>` | previous buffer |
| `<leader>bd` | delete buffer |

## Editing

| Key | Action |
|-----|--------|
| `<A-j>` / `<A-k>` | move line/selection down / up |
| `<` / `>` (visual) | indent and keep selection |
| `<C-d>` / `<C-u>` | half-page down / up, centered |
| `n` / `N` | next / prev search match, centered |
| `<leader>p` (visual) | paste over selection without yanking it |

## Diagnostics

| Key | Action |
|-----|--------|
| `]d` / `[d` | next / previous diagnostic |
| `<leader>e` | open line diagnostics float |

## From plugins (quick reference)

| Key | Action | Doc |
|-----|--------|-----|
| `<leader><space>` / `<leader>ff` | find files | [Navigation](07-navigation.md) |
| `<leader>fg` | live grep | [Navigation](07-navigation.md) |
| `gd` `gr` `K` `<leader>ca` `<leader>cr` | LSP nav / hover / action / rename | [LSP](05-lsp-and-languages.md) |
| `<leader>cf` | format buffer | [LSP](05-lsp-and-languages.md) |
| `]h` `[h` `<leader>h*` | git hunks | [Git](08-git.md) |
| `<leader>gg` | LazyGit | [Git](08-git.md) |
| `-` | file explorer (oil) | [Navigation](07-navigation.md) |
| `s` `S` | flash jump / treesitter | [Navigation](07-navigation.md) |
| `ys` `cs` `ds` | surround add / change / delete | [Plugins](04-plugins.md) |
| `<leader>l` | open Lazy UI | [Plugins](04-plugins.md) |

## Incremental selection (treesitter)

| Key | Action |
|-----|--------|
| `<C-space>` | start / expand selection by node |
| `<bs>` | shrink selection |

---

Next: [Plugins](04-plugins.md)
