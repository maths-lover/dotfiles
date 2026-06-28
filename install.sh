#!/usr/bin/env bash
# install.sh - bootstrap these dotfiles on a fresh macOS machine.
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
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$([ -x /opt/homebrew/bin/brew ] && /opt/homebrew/bin/brew shellenv || /usr/local/bin/brew shellenv)"

# 2. GNU Stow
command -v stow >/dev/null 2>&1 || { info "Installing stow..."; brew install stow; }

# 3. Pre-create real dirs that MUST NOT be folded into the repo by stow.
#    (If ~/.ssh didn't exist, stow would symlink the whole dir into the repo and
#    your private keys would resolve inside the dotfiles repo - never that.)
mkdir -p "$HOME/.ssh/control" && chmod 700 "$HOME/.ssh" "$HOME/.ssh/control"
mkdir -p "$HOME/.config"

# 4. Symlink configs into ~ (folds whole dirs that don't exist yet, e.g. nvim;
#    descends into existing dirs like ~/.ssh & ~/.config/zsh so secrets/runtime
#    files stay put as real files)
info "Stowing dotfiles -> \$HOME..."
stow -d "$DOT" -t "$HOME" --restow .

# config.local holds private ssh hosts and is git-ignored; seed an empty one so
# the `Include` in ~/.ssh/config resolves cleanly.
if [[ ! -f "$HOME/.ssh/config.local" ]]; then
  printf '# Private/machine-specific ssh hosts. Not tracked in git.\n' > "$HOME/.ssh/config.local"
  chmod 600 "$HOME/.ssh/config.local"
fi

# 5. Install everything else (tools, fonts, Ghostty, fzf-tab, ~/.zshenv)
info "Running setup_zsh.sh..."
"$HOME/.config/zsh/setup_zsh.sh"

# 6. Python toolchain via uv (uv itself comes from the Brewfile in step 5).
#    A managed interpreter + the editor LSPs as global, self-contained tools.
#    These are uv-managed (not brew/Mason), so they live here, not the Brewfile.
if command -v uv >/dev/null 2>&1; then
  info "Setting up uv Python toolchain (interpreter + ty + ruff + debugpy)..."
  uv python install 3.13
  uv tool install ty             # type checker + LSP (Astral; replaces pyright)
  uv tool install ruff           # linter + import sorting LSP (format via conform)
  uv tool install debugpy        # provides debugpy-adapter for nvim-dap debugging
fi

printf '\n%sDone.%s  Start a new shell:  exec zsh\n' "$bold" "$reset"
