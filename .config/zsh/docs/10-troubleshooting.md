[← Documentation index](README.md)

# 10. Troubleshooting

| Symptom | Fix |
|---------|-----|
| Boxes / missing glyphs in the prompt | Terminal font must be a Monaspice **Nerd Font** — check `ghostty/config`, reinstall with `brew bundle --file ~/.config/Brewfile` |
| `theme` says "not found" | `theme list` to see valid names; use an alias or the exact Ghostty theme name (quote spaces) |
| Theme didn't change in another window | OSC only recolors the current window; new windows pick it up from the persisted config |
| RAM gauge stuck / wrong | It's computed by `_starship_ram_pct` (precmd) → `STARSHIP_RAM_PCT`; ensure that hook still loads in `.zshrc` |
| Slow startup | Profile with `for i in 1 2 3; do time zsh -ic exit; done` — usually a plugin or a heavy `local.zsh` |
| Completion missing after installing a tool | `rm ~/.cache/zsh/zcompdump-*; exec zsh` |
| `cat` / `ls` misbehaving in a pasted script | bypass the alias: `\cat`, `command ls` |
| ESC feels laggy in vim mode | `KEYTIMEOUT=1` should be set in `.zshrc`; confirm with `echo $KEYTIMEOUT` |
| Arrow keys insert characters in vim mode | terminal not sending standard sequences — ensure Ghostty (not an odd `TERM`); check `bindkey` for `^[[A`/`^[[B` |
| Old `~/.zshrc` interfering | this setup uses `ZDOTDIR`; `~/.zshenv` must contain only the bootstrap, and there should be no `~/.zshrc` / `~/.zprofile` in `$HOME` |
| `brew` / tools not on `PATH` in a new shell | `.zprofile` runs `brew shellenv` for login shells; start a login shell or `source ~/.config/zsh/.zprofile` |
| Man pages don't open in neovim | `echo $MANPAGER` should be `nvim +Man!`; set in `.zshenv` when `nvim` is present |
| Git asks for SSH key passphrase when committing | The key isn't in the agent. `~/.ssh/config` has `AddKeysToAgent`/`UseKeychain`, so `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` once caches it in Keychain; afterwards any `ssh`/`git` use loads it automatically |
| `ssh: Bad owner or permissions` | `chmod 700 ~/.ssh`; the tracked `~/.ssh/config` is a symlink into `~/dotfiles` — its repo file must not be group/world-writable |
| Need a private/internal SSH host | add it to `~/.ssh/config.local` (git-ignored, machine-specific); it's `Include`d first so it overrides the global defaults |

## Useful diagnostics

```sh
exec zsh                                  # reload the shell
echo $ZDOTDIR $EDITOR $MANPAGER           # key env
bindkey -lL main                          # which keymap is active (viins = vim mode)
ghostty +validate-config --config-file ~/.config/ghostty/config
ghostty +list-fonts | grep Monaspice      # installed font families
starship explain                          # what the prompt is rendering
```

---

[↑ Documentation index](README.md) · [↑ Project README](../README.md)
