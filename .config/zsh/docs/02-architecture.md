[← Documentation index](README.md)

# 2. Architecture

## ZDOTDIR

All zsh files live in `~/.config/zsh` instead of cluttering `$HOME`. The only file
that must stay in `$HOME` is a tiny bootstrap that sets `ZDOTDIR` and hands off:

```sh
# ~/.zshenv (the only zsh file in $HOME)
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
```

## Managed with GNU Stow

The configs live in a git repo at **`~/dotfiles`** (mirroring `$HOME`), and
**Stow** symlinks them into place. So the real files are in `~/dotfiles/.config/…`,
and `~/.config/…` entries are symlinks pointing at them. Runtime files (plugins,
caches, `.active-theme`) and other apps' configs stay as real files in `~/.config`
and are never touched.

```
~/dotfiles/                    ← git repo (SSH-signed commits)
├── install.sh                 bootstrap: brew → stow → setup_zsh.sh
├── .gitignore
└── .config/                   ← stowed into ~/  (so it lands in ~/.config)
    ├── Brewfile
    ├── starship.toml
    ├── ghostty/config
    └── zsh/…

# after `stow`:  ~/.config/zsh/.zshrc → ~/dotfiles/.config/zsh/.zshrc  (symlink)
```

Re-link after adding a **new** file: `cd ~/dotfiles && stow --restow .`
(editing existing files needs nothing — they're symlinks straight into the repo).

## File layout (logical, as seen under `~/.config`)

```
~/.zshenv                      Bootstrap → ZDOTDIR (real file; written by setup_zsh.sh)
~/.config/                     (tracked entries are symlinks into ~/dotfiles)
├── Brewfile                   Declarative list of every package/cask/font
├── starship.toml              Prompt definition (the HUD)
├── ghostty/config             Terminal: font, theme, padding, keybinds
└── zsh/
    ├── .zshenv                Universal env (XDG dirs, EDITOR, MANPAGER, LANG)
    ├── .zprofile              Login shells: Homebrew shellenv, PATH
    ├── .zshrc                 Interactive shell — the main config
    ├── aliases.zsh            Aliases
    ├── functions.zsh          Helper functions
    ├── theme.zsh              `theme` colorscheme switcher
    ├── setup_zsh.sh           Reproducible installer
    ├── docs/                  This documentation
    ├── plugins/fzf-tab/       Vendored plugin — real, untracked (re-cloned by setup)
    ├── local.zsh              Optional per-machine overrides — real, untracked
    └── .active-theme          Current-theme state — real, untracked
```

### Runtime data (kept out of the config, XDG)

| Data | Location |
|------|----------|
| History | `~/.local/state/zsh/history` |
| Completion cache | `~/.cache/zsh/zcompdump-*` |

## Startup order

| Order | File | When | Purpose |
|------:|------|------|---------|
| 1 | `~/.zshenv` | always | set `ZDOTDIR`, source `$ZDOTDIR/.zshenv` |
| 2 | `$ZDOTDIR/.zshenv` | always | XDG dirs, `EDITOR`, `MANPAGER`, `LANG` |
| 3 | `$ZDOTDIR/.zprofile` | login | Homebrew `shellenv`, `PATH` |
| 4 | `$ZDOTDIR/.zshrc` | interactive | everything else |

Inside `.zshrc`, the load sequence is: options & history → completion → vim mode &
keybindings → fzf integration → plugins → tool integrations (zoxide, bat, eza) →
`theme.zsh` → `aliases.zsh` → `functions.zsh` → Starship → `local.zsh`.

## Customization

Create **`~/.config/zsh/local.zsh`** for per-machine settings you don't want to
commit. It's sourced **last**, so it overrides everything:

```sh
# ~/.config/zsh/local.zsh
export THEME_DEFAULT_DARK=dracula      # used by `theme dark`/`toggle`
export THEME_DEFAULT_LIGHT=latte
alias k=kubectl
path+=("$HOME/work/bin")
```

| To change… | Edit… |
|------------|-------|
| aliases | `aliases.zsh` |
| functions | `functions.zsh` |
| the prompt | `starship.toml` (see [Prompt](07-prompt.md)) |
| the terminal | `ghostty/config` |
| installed packages | `Brewfile`, then `brew bundle --file ~/.config/Brewfile` |
| themes / defaults | `theme.zsh` or `local.zsh` (see [Themes](08-themes.md)) |

---

Next: [Tools →](03-tools.md)
