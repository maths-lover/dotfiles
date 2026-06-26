# Neovim

A hand-built, modular Neovim config built on lazy.nvim. It matches the rest of the
dotfiles: vim-mode shell ergonomics, Monaspace Nerd Font, and the live `theme`
colorscheme switcher. Works in the terminal and in Neovide.

| | |
|---|---|
| Plugin manager | lazy.nvim |
| Completion | blink.cmp |
| LSP install | Mason (auto) |
| Languages | Lua, Bash, Markdown, JSON/YAML/TOML, Python, JS/TS+Web, Go, Rust, C/C++, Java, Zig |
| Colorscheme | follows the OS `theme` switcher (tokyonight / catppuccin / gruvbox / dracula / rose-pine) |
| GUI | Neovide supported |

## Install

Part of the dotfiles. On a fresh machine, `~/dotfiles/install.sh` stows this into
`~/.config/nvim`; first launch of `nvim` auto-installs lazy.nvim, plugins, and
(via Mason) the language servers and formatters.

## Documentation

Full docs live in [`docs/`](docs/README.md):

| #  | Doc | Contents |
|---:|-----|----------|
| 1  | [Getting started](docs/01-getting-started.md) | Install, first launch, bootstrap, reloading |
| 2  | [Architecture](docs/02-architecture.md) | File layout, load order, adding plugins/languages |
| 3  | [Keymaps](docs/03-keymaps.md) | Leader, windows, buffers, editing, which-key |
| 4  | [Plugins](docs/04-plugins.md) | Every plugin, by area |
| 5  | [LSP & languages](docs/05-lsp-and-languages.md) | Mason, servers, formatting, diagnostics |
| 6  | [Completion](docs/06-completion.md) | blink.cmp + snippets |
| 7  | [Navigation & search](docs/07-navigation.md) | fzf-lua, oil, flash, treesitter objects |
| 8  | [Git](docs/08-git.md) | gitsigns + lazygit |
| 9  | [Theme sync](docs/09-theme-sync.md) | Following the OS colorscheme |
| 10 | [Neovide](docs/10-neovide.md) | GUI settings |
| 11 | [macOS integration](docs/11-macos-integration.md) | Open in apps, clipboard synergy |
| 12 | [Notes](docs/12-notes.md) | markdown-oxide, render-markdown, obsidian |
| 13 | [Troubleshooting](docs/13-troubleshooting.md) | Symptom -> fix |
