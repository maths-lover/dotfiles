[← Documentation index](README.md)

# 1. Getting started

## Fresh-machine install

The dotfiles are a **GNU Stow** repo cloned to `~/dotfiles`; Stow symlinks the
configs into `~/.config`. One command does everything:

```sh
git clone <your-dotfiles-repo> ~/dotfiles
~/dotfiles/install.sh   # Homebrew + Stow → symlinks → setup_zsh.sh
exec zsh
```

`install.sh` installs Homebrew + Stow (if missing), runs `stow` to symlink the
configs, then runs `setup_zsh.sh`.

### What `setup_zsh.sh` does

1. Installs the **Xcode Command Line Tools** (if missing).
2. Installs **Homebrew** (if missing).
3. Runs `brew bundle` against `~/.config/Brewfile` — all CLI tools, zsh plugins,
   **Ghostty**, and the **Monaspace Nerd Font**.
4. Vendors the **`fzf-tab`** plugin (not in Homebrew).
5. Creates runtime dirs (`~/.local/state/zsh`, `~/.cache/zsh`, `~/.local/bin`).
6. Writes the **`~/.zshenv` bootstrap** that points zsh at `~/.config/zsh`.
7. Primes the `tldr` cache.

It backs up any existing `~/.zshenv` before writing, and is safe to re-run any time.

## Reloading after edits

| Edited | Apply with |
|--------|-----------|
| any zsh file (`.zshrc`, `aliases.zsh`, …) | `exec zsh` (or the `reload` alias) |
| `starship.toml` | next prompt (instant) |
| `ghostty/config` | `Cmd+Shift+,` in Ghostty (or restart) |

## Maintenance

```sh
brew update && brew upgrade                      # update everything
brew bundle --file ~/.config/Brewfile            # install anything new in the Brewfile
brew bundle cleanup --file ~/.config/Brewfile    # (dry-run) list packages not in the Brewfile
tldr --update                                    # refresh cheatsheet cache
```

After adding a new tool, record it in `~/.config/Brewfile` so it survives a rebuild.

---

Next: [Architecture →](02-architecture.md)
