#!/usr/bin/env bash
# install.sh — bootstrap these dotfiles on a fresh macOS machine.
#
#   git clone <repo> ~/dotfiles && ~/dotfiles/install.sh
#
# Idempotent: installs Homebrew + Stow if missing, symlinks the configs into ~,
# then runs setup_zsh.sh (tools, fonts, Ghostty, fzf-tab, ~/.zshenv bootstrap).

set -euo pipefail
DOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

bold=$(tput bold 2>/dev/null || true); reset=$(tput sgr0 2>/dev/null || true)
info() { printf '%s==>%s %s\n' "$bold" "$reset" "$*"; }

[[ "$(uname -s)" == "Darwin" ]] || { echo "macOS only."; exit 1; }

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew…"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$([ -x /opt/homebrew/bin/brew ] && /opt/homebrew/bin/brew shellenv || /usr/local/bin/brew shellenv)"

# 2. GNU Stow
command -v stow >/dev/null 2>&1 || { info "Installing stow…"; brew install stow; }

# 3. Symlink configs into ~ (folds whole dirs that don't exist yet, e.g. nvim;
#    descends into existing dirs like ~/.config/zsh so runtime files stay put)
info "Stowing dotfiles → \$HOME…"
stow -d "$DOT" -t "$HOME" --restow .

# 4. Install everything else (tools, fonts, Ghostty, fzf-tab, ~/.zshenv)
info "Running setup_zsh.sh…"
"$HOME/.config/zsh/setup_zsh.sh"

printf '\n%sDone.%s  Start a new shell:  exec zsh\n' "$bold" "$reset"
