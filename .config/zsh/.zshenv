# ~/.config/zsh/.zshenv  (ZDOTDIR)
# Read for EVERY zsh (login, interactive, scripts). Keep it minimal & fast.
# Sourced manually from ~/.zshenv after ZDOTDIR is set.

# -- PATH hygiene --------------------------------------------------------------
# Tie path<->PATH and keep them de-duplicated. -U makes zsh drop later repeats
# on every assignment, so unconditional prepends in .zprofile (brew, ~/.local/bin,
# openjdk) can't stack up across nested/login/`exec zsh` shells. Set here so it's
# in force before any PATH edit. fpath included (built in .zshrc) — never wants dupes.
typeset -U path PATH fpath FPATH

# -- XDG base directories ------------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# -- Sensible defaults ---------------------------------------------------------
# Prefer neovim; fall back gracefully ($+commands is a fast, zsh-native check).
if   (( $+commands[nvim] )); then
  export EDITOR=nvim
  # Read man pages in neovim: syntax highlighting + vim nav (gO = TOC, C-] = follow, q = quit)
  export MANPAGER='nvim +Man!'
elif (( $+commands[vim]  )); then export EDITOR=vim
else export EDITOR=vi; fi
export VISUAL="$EDITOR"
export PAGER="${PAGER:-less}"
export LESS="-R"            # render colors/ANSI in less
export LANG="${LANG:-en_US.UTF-8}"

# Point ripgrep at its config (max-columns, smart-case, hidden, custom types).
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
