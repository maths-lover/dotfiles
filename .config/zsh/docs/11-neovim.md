[← Documentation index](README.md)

# 11. Neovim

A hand-built, modular **lazy.nvim** config that matches the rest of the setup:
vim-mode shell, Monaspace font, and the live `theme` colorscheme switcher. Works
in the terminal and in **Neovide**.

## Structure

```
~/.config/nvim/
├── init.lua                 leader keys + load order
├── lua/config/
│   ├── options.lua          vim.opt settings
│   ├── keymaps.lua          general keymaps
│   ├── autocmds.lua         autocommands
│   ├── lazy.lua             bootstrap lazy.nvim
│   ├── theme.lua            colorscheme sync with the OS `theme`
│   └── neovide.lua          GUI settings (Neovide only)
├── lua/plugins/             one file per area (see below)
└── lazy-lock.json           pinned plugin versions (tracked)
```

Plugin areas: `colorschemes`, `treesitter`, `lsp`, `completion` (blink.cmp),
`formatting` (conform), `fzf` (fzf-lua), `git` (gitsigns + lazygit), `editor`
(which-key, surround, oil, flash, mini.ai/pairs), `ui` (lualine, indent guides).

## Theme sync

Neovim reads `~/.config/zsh/.active-theme` (written by the shell `theme` command)
and picks the matching colorscheme + background. So `theme dracula` in the terminal
→ nvim opens in Dracula; `theme gruvbox-light` → both go light.

- Installed schemes: tokyonight, catppuccin, gruvbox, dracula, rose-pine.
- Re-syncs on **FocusGained** and via a file-watch (instant while running).
- Manual: `:ThemeSync`. Customize the mapping in `lua/config/theme.lua`.

## Languages

LSP + treesitter + formatting for: **Lua, Bash, Markdown, JSON/YAML/TOML, Python,
JS/TS + Web, Go, Rust, C/C++, Java, Zig**.

- **Servers/formatters** auto-install via **Mason** on first use (`:Mason` to view).
- **Toolchains** come from Homebrew (`node`, `go`, `rust`, `zig`, `openjdk`; clang
  via Xcode CLT) — see the `Brewfile`.
- **Format on save** via conform (`:FormatDisable` / `:FormatEnable` to toggle,
  `<leader>cf` to format manually).

## Key maps (leader = `Space`)

| Key | Action |
|-----|--------|
| `<leader><space>` / `<leader>ff` | find files (fzf-lua) |
| `<leader>fg` | live grep · `<leader>/` search buffer |
| `<leader>fb` / `<leader>fr` | buffers / recent files |
| `gd` `gr` `gI` `gy` | LSP definition / references / impl / type |
| `K` · `<leader>ca` · `<leader>cr` | hover · code action · rename |
| `<leader>cf` | format · `<leader>cs` symbols · `<leader>ci` inlay hints |
| `]d` `[d` · `]h` `[h` | next/prev diagnostic · next/prev git hunk |
| `<leader>h*` | git hunk stage/reset/preview/blame |
| `<leader>gg` | LazyGit |
| `-` | file explorer (oil) · `s` flash jump |
| `ys` `cs` `ds` | surround add/change/delete (like the shell) |
| `<C-h/j/k/l>` | window navigation |

`<leader>?` shows buffer-local keymaps (which-key).

## Neovide

GUI settings live in `lua/config/neovide.lua` (applied only under Neovide): Monaspace
font, padding/opacity matching Ghostty, cursor animations, and macOS shortcuts
(`Cmd-C/V/S/A`, `Cmd-=/-/0` to zoom). Launch with `neovide` (from a shell so it
inherits PATH — needed for the Java LSP).

## Adding things

- **A plugin** → new file (or edit one) in `lua/plugins/`, then `:Lazy sync`.
- **A language** → add its treesitter parser to `treesitter.lua`, its server to
  `ensure_installed` in `lsp.lua`, and a formatter in `formatting.lua`.
- **Re-link after new files** → `cd ~/dotfiles && stow --restow .` (nvim is folded,
  so files added under `~/.config/nvim` are already in the repo).

---

[↑ Documentation index](README.md)
