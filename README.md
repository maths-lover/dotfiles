# dotfiles

Personal macOS terminal configuration, managed with **GNU Stow**.

A fast, hacker-flavored **zsh** setup built around **Homebrew**, **Starship**,
**Ghostty**, **neovim**, and modern Rust/Go CLI tools - with vim mode, a custom
prompt HUD, and a live light/dark colorscheme switcher.

## Layout

The repo mirrors `$HOME`. Stow symlinks each tracked file into place, leaving every
other file in `~/.config` (other apps, caches, state) untouched.

```
dotfiles/
|-- install.sh            one-shot bootstrap (brew -> stow -> setup)
|-- .gitignore
|-- pi/                   SEPARATE stow package: pi agent config (see below)
|   `-- .pi/agent/        settings, agents, prompts, extensions, skills
`-- .config/
    |-- Brewfile          every package / cask / font (declarative)
    |-- starship.toml     the prompt
    |-- ghostty/config    terminal emulator
    |-- nvim/             neovim config + docs
    `-- zsh/              the shell config + docs + installer
```

`pi/` is its own stow package, deliberately kept out of the root `stow .` (it is
listed in `.stow-local-ignore`). See [pi agent](#pi-agent) below.

After stow:

```
~/.config/zsh/.zshrc      -> ~/dotfiles/.config/zsh/.zshrc      (symlink)
~/.config/starship.toml   -> ~/dotfiles/.config/starship.toml   (symlink)
...                          (runtime files like plugins/ stay real, untracked)
```

## Install on a new machine

```sh
git clone <this-repo> ~/dotfiles
~/dotfiles/install.sh          # installs Homebrew + stow, symlinks configs, installs everything
exec zsh
```

`install.sh` is idempotent: it installs Homebrew and Stow if missing, symlinks the
configs (`stow`), then runs `setup_zsh.sh` (all CLI tools, fonts, Ghostty, the
`fzf-tab` plugin, and the `~/.zshenv` bootstrap).

## Day-to-day

```sh
cd ~/dotfiles && stow --restow .   # re-link after adding new files
git add -A && git commit           # commits are SSH-signed
```

Edit configs in `~/.config/...` as usual - they are symlinks, so you are editing the
repo. New *files* need a `stow --restow .` to be linked.

## pi agent

The [pi](https://github.com/earendil-works) coding-agent config lives in its own
stow package, `pi/`, so it can be installed independently of the shell setup.
It tracks only *setup* — `settings.json`, `agents/`, `prompts/`, `extensions/`
(caveman, greeter, save-session, cockpit, gitlab, subagent) and `skills/`.

Secrets and machine state stay untracked and are **never** moved into the repo:
`auth.json`, `trust.json`, `models-store.json`, `sessions/`, `saved-sessions/`.
`~/.pi/agent` therefore stays a real directory; only the tracked children are
symlinked into it.

```sh
./install.sh pi     # set up ONLY the pi agent module (brew + stow + link)
./install.sh        # full machine setup, which includes the pi module
cd ~/dotfiles && stow --restow pi   # re-link after adding pi files
```

## Documentation

- **zsh / terminal**: [`.config/zsh/docs/`](.config/zsh/docs/README.md) - getting
  started, architecture, tools, keybindings, navigation, prompt, themes, fonts,
  troubleshooting.
- **neovim**: [`.config/nvim/docs/`](.config/nvim/docs/README.md) - getting started,
  architecture, keymaps, plugins, LSP & languages, completion, navigation, git,
  theme sync, Neovide, troubleshooting.
