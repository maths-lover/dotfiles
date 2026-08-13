#!/usr/bin/env bash
# install.sh - bootstrap these dotfiles on a fresh macOS machine.
#
#   git clone <repo> ~/dotfiles && ~/dotfiles/install.sh
#
# Idempotent: installs Homebrew + Stow if missing, symlinks the configs into ~,
# then runs setup_zsh.sh (tools, fonts, Ghostty, fzf-tab, ~/.zshenv bootstrap).

set -euo pipefail
DOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Module selector:  ./install.sh        -> everything (includes the pi module)
#                   ./install.sh pi     -> ONLY the pi agent module, nothing else
MODULE="${1:-all}"

bold=$(tput bold 2>/dev/null || true); reset=$(tput sgr0 2>/dev/null || true)
info() { printf '%s==>%s %s\n' "$bold" "$reset" "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Make an already-installed Homebrew visible (macOS or Linuxbrew); no-op if absent.
for _b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [ -x "$_b" ] && eval "$("$_b" shellenv)" && break
done

# On macOS, guarantee Homebrew (used for everything). No-op on Linux.
ensure_brew_mac() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  have brew && return 0
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$([ -x /opt/homebrew/bin/brew ] && /opt/homebrew/bin/brew shellenv || /usr/local/bin/brew shellenv)"
}

# Cross-platform installers for the pi module's two needs (stow + pi runtime).
ensure_stow() {
  have stow && return 0
  info "Installing GNU stow..."
  if   have brew;    then brew install stow
  elif have apt-get; then sudo apt-get update -qq && sudo apt-get install -y stow
  elif have dnf;     then sudo dnf install -y stow
  elif have pacman;  then sudo pacman -S --noconfirm stow
  elif have zypper;  then sudo zypper install -y stow
  else echo "Please install GNU stow, then re-run."; exit 1; fi
}
ensure_pi() {
  have pi && return 0
  info "Installing pi (pi-coding-agent)..."
  if   have brew; then brew install pi-coding-agent                    # macOS + Linuxbrew (homebrew-core)
  elif have npm;  then npm install -g @earendil-works/pi-coding-agent  # any OS with Node.js
  else echo "pi not installed: install Homebrew or Node.js (npm), then re-run './install.sh pi'."; fi
}

# pi agent — its own stow package (pi/), kept separate from the root dotfiles so
# it can be installed on its own, on macOS OR Linux. ~/.pi/agent stays a REAL
# directory: it also holds auth.json (secrets), the model cache, trust.json and
# session history, all intentionally NOT tracked in this repo.
setup_pi() {
  info "Setting up pi agent module (stow package: pi)..."
  ensure_brew_mac      # macOS: guarantees brew; Linux: no-op
  ensure_stow          # brew / apt / dnf / pacman / zypper
  ensure_pi            # brew (homebrew-core) or npm (@earendil-works/pi-coding-agent)
  mkdir -p "$HOME/.pi/agent"
  stow -d "$DOT" -t "$HOME" --restow pi
}

# The pi module is cross-platform, so handle it BEFORE the macOS-only full setup.
if [[ "${MODULE}" == "pi" ]]; then
  setup_pi
  printf '\n%spi module installed.%s  Config symlinked into ~/.pi/agent (secrets/sessions left untouched).\n' "$bold" "$reset"
  exit 0
fi

# ---- Everything below (full machine setup) is macOS-only ----
[[ "$(uname -s)" == "Darwin" ]] || {
  echo "Full install is macOS-only (Homebrew casks, fonts, IINA, defaults writes)."
  echo "For pi config on Linux, run:  ./install.sh pi"
  exit 1
}

# 1. Homebrew
ensure_brew_mac

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

# 4b. pi agent — separate stow package (see setup_pi above).
setup_pi

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

# 7. IINA: read our high-quality mpv config from ~/.config/mpv (advanced
#    settings). IINA itself comes from the Brewfile cask in step 5.
if [[ -d /Applications/IINA.app ]]; then
  info "Configuring IINA to use ~/.config/mpv ..."
  defaults write com.colliderli.iina enableAdvancedSettings -bool true
  defaults write com.colliderli.iina useUserDefinedConfDir -bool true
  defaults write com.colliderli.iina userDefinedConfDir -string "$HOME/.config/mpv"
  mkdir -p "$HOME/.local/state/mpv/watch_later"
fi

printf '\n%sDone.%s  Start a new shell:  exec zsh\n' "$bold" "$reset"
