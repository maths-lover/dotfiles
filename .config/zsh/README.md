# Zsh Setup

A fast, modern, hacker-flavored zsh configuration for macOS (Apple Silicon), built
around **Homebrew**, **Starship**, **Ghostty**, **neovim**, and a suite of Rust/Go
CLI tools. Config lives under `~/.config` (XDG), the shell runs in **vim mode**, the
prompt is a custom **HUD**, and the colorscheme is **switchable live** (light/dark).

| | |
|---|---|
| **Editor** | neovim (`$EDITOR`, man pages) |
| **Prompt** | Starship — two-line HUD |
| **Terminal** | Ghostty + Monaspace Nerd Fonts |
| **Startup** | ~0.05s |

## Install (new machine)

```sh
git clone <your-dotfiles-repo> ~/.config   # must contain zsh/, ghostty/, Brewfile, starship.toml
~/.config/zsh/setup_zsh.sh                 # idempotent installer
exec zsh
```

## Documentation

Full docs live in **[`docs/`](docs/README.md)**:

| # | Doc | Contents |
|--:|-----|----------|
| 1 | [Getting started](docs/01-getting-started.md) | Install, reload, maintenance |
| 2 | [Architecture](docs/02-architecture.md) | File layout, startup order, customization |
| 3 | [Tools](docs/03-tools.md) | Every installed CLI tool |
| 4 | [Shell & vim mode](docs/04-shell-and-vim.md) | History, completion, keybindings |
| 5 | [Aliases & functions](docs/05-aliases-and-functions.md) | All shortcuts & helpers |
| 6 | [Navigation](docs/06-navigation.md) | zoxide + fzf workflow |
| 7 | [Prompt](docs/07-prompt.md) | Starship HUD anatomy |
| 8 | [Themes](docs/08-themes.md) | Live colorscheme switcher |
| 9 | [Fonts](docs/09-fonts.md) | Monaspace Nerd Fonts |
| 10 | [Troubleshooting](docs/10-troubleshooting.md) | Symptom → fix |
