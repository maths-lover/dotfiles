[← Documentation index](README.md)

# 3. Tools

All packages are declared in `~/.config/Brewfile`. Run `brew bundle --file
~/.config/Brewfile` to install or sync them.

## CLI tools

| Tool | Command | Replaces / purpose |
|------|---------|--------------------|
| ripgrep | `rg` | grep (fast, gitignore-aware) |
| fd | `fd` | find (fast, friendly syntax) |
| fzf | `fzf` | fuzzy finder (history, files, dirs) |
| bat | `bat` / `cat` | cat with syntax highlighting |
| eza | `eza` / `ls` | modern ls — icons, git, tree |
| zoxide | `z`, `zi` | smarter cd (frecency ranking) |
| git-delta | `delta` | rich git diffs |
| lazygit | `lazygit` / `lg` | git TUI |
| gh | `gh` | GitHub CLI |
| btop | `btop` / `top` | resource monitor |
| dust | `dust` | du, but intuitive |
| procs | `procs` | ps, modern |
| fastfetch | `fastfetch` | system info splash |
| jq | `jq` | JSON processor |
| yq | `yq` | YAML/JSON/XML processor |
| tealdeer | `tldr` | community cheatsheet man pages |
| httpie | `http` | friendly HTTP client |
| zellij | `zellij` | terminal multiplexer (modern tmux) |
| neovim | `nvim` | the editor (`$EDITOR`, `$MANPAGER`) |
| starship | `starship` | the prompt |

## Shell plugins

| Plugin | Effect |
|--------|--------|
| zsh-autosuggestions | gray inline suggestion from history/completion |
| zsh-syntax-highlighting | colors the command line as you type |
| zsh-completions | extra completion definitions |
| fzf-tab *(vendored)* | turns `<Tab>` into an fzf menu with previews |

## App & fonts (casks)

| Cask | Purpose |
|------|---------|
| `ghostty` | terminal emulator |
| `font-monaspice-nerd-font` | Monaspace Nerd Fonts (see [Fonts](09-fonts.md)) |

> Many tools are integrated into the shell — see
> [Navigation](06-navigation.md) (fzf/zoxide), [Aliases & functions](05-aliases-and-functions.md),
> and [Prompt](07-prompt.md).

---

Next: [Shell & vim mode →](04-shell-and-vim.md)
