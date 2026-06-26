[Documentation index](README.md)

# 8. Git

Configured in `lua/plugins/git.lua`.

## gitsigns

Shows added/changed/removed lines in the sign column and provides hunk actions.
Keymaps are buffer-local (active in a git repo):

| Key | Action |
|-----|--------|
| `]h` / `[h` | next / previous hunk |
| `<leader>hs` | stage hunk |
| `<leader>hr` | reset hunk |
| `<leader>hS` | stage buffer |
| `<leader>hp` | preview hunk |
| `<leader>hb` | blame line (full) |
| `<leader>hd` | diff this |
| `<leader>hB` | toggle inline line blame |

## lazygit

The lazygit TUI inside Neovim (you already use lazygit in the shell).

| Key | Action |
|-----|--------|
| `<leader>gg` | open LazyGit |

Commands: `:LazyGit`, `:LazyGitCurrentFile`, `:LazyGitConfig`.

## fzf-lua git pickers

| Key | Action |
|-----|--------|
| `<leader>gc` | browse git commits |
| `<leader>gs` | git status picker |

---

Next: [Theme sync](09-theme-sync.md)
