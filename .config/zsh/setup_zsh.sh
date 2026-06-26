#!/usr/bin/env bash
# setup_zsh.sh - reproduce this terminal setup on a fresh macOS machine.
#
# Idempotent: safe to re-run. It will
#   1. install the Xcode Command Line Tools (if missing)
#   2. install Homebrew (if missing)
#   3. install every CLI tool, zsh plugin, Ghostty, and the Monaspace Nerd Font
#      from ~/.config/Brewfile
#   4. vendor the fzf-tab plugin
#   5. wire up ~/.zshenv so zsh reads its config from ~/.config/zsh (ZDOTDIR)
#
# Prereq: this repo/config is checked out at ~/.config
#   (these files live in ~/.config/zsh, ~/.config/Brewfile, ~/.config/starship.toml, ...)
#
# Usage:
#   ~/.config/zsh/setup_zsh.sh

set -euo pipefail

# -- Resolve locations ---------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"   # .../.config/zsh
CONFIG_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"                       # .../.config
BREWFILE="$CONFIG_DIR/Brewfile"

# -- Pretty logging ------------------------------------------------------------
bold=$(tput bold 2>/dev/null || true); reset=$(tput sgr0 2>/dev/null || true)
green=$(tput setaf 2 2>/dev/null || true); blue=$(tput setaf 4 2>/dev/null || true)
yellow=$(tput setaf 3 2>/dev/null || true)
info()  { printf '%s==>%s %s\n' "$blue$bold" "$reset" "$*"; }
ok()    { printf '%s  +%s %s\n' "$green" "$reset" "$*"; }
warn()  { printf '%s  !%s %s\n' "$yellow" "$reset" "$*"; }

[[ "$(uname -s)" == "Darwin" ]] || { echo "This script is for macOS only."; exit 1; }

# -- 1. Xcode Command Line Tools -----------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  info "Installing Xcode Command Line Tools (a GUI prompt will appear)..."
  xcode-select --install || true
  echo "Finish the CLT installation, then re-run this script."
  exit 0
fi
ok "Xcode Command Line Tools present"

# -- 2. Homebrew ---------------------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW=/opt/homebrew/bin/brew
elif [[ -x /usr/local/bin/brew ]]; then
  BREW=/usr/local/bin/brew
else
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW=/opt/homebrew/bin/brew; [[ -x $BREW ]] || BREW=/usr/local/bin/brew
fi
eval "$("$BREW" shellenv)"
ok "Homebrew ready ($BREW)"

# -- 3. Packages, plugins, Ghostty, fonts (via Brewfile) -----------------------
if [[ -f "$BREWFILE" ]]; then
  info "Installing everything from $BREWFILE ..."
  brew bundle --file "$BREWFILE"
  ok "Brewfile installed"
else
  warn "No Brewfile at $BREWFILE - skipping bulk install"
fi

# -- 4. fzf-tab plugin (not in homebrew-core) ----------------------------------
FZF_TAB_DIR="$SCRIPT_DIR/plugins/fzf-tab"
if [[ ! -d "$FZF_TAB_DIR" ]]; then
  info "Cloning fzf-tab..."
  mkdir -p "$SCRIPT_DIR/plugins"
  git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git "$FZF_TAB_DIR"
  ok "fzf-tab cloned"
else
  ok "fzf-tab already present"
fi

# -- 5. Runtime directories ----------------------------------------------------
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" \
         "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" \
         "$HOME/.local/bin"
ok "Runtime directories created"

# -- 6. ~/.zshenv bootstrap (points zsh at ~/.config/zsh) ----------------------
ZSHENV="$HOME/.zshenv"
read -r -d '' BOOTSTRAP <<'EOF' || true
# ~/.zshenv - bootstrap only.
# This is the one zsh file that must live in $HOME. It points zsh at the real
# config directory (XDG) and hands off; everything else lives in ~/.config/zsh.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
if [[ ! -f "$ZSHENV" ]] || ! grep -q 'ZDOTDIR=.*\.config/zsh' "$ZSHENV"; then
  [[ -f "$ZSHENV" ]] && cp -p "$ZSHENV" "$ZSHENV.bak.$(date +%Y%m%d-%H%M%S)" && \
    warn "Existing ~/.zshenv backed up"
  printf '%s\n' "$BOOTSTRAP" > "$ZSHENV"
  ok "Wrote ~/.zshenv bootstrap"
else
  ok "~/.zshenv already points at ~/.config/zsh"
fi

# -- 7. tldr cache -------------------------------------------------------------
if command -v tldr >/dev/null 2>&1; then
  info "Priming tldr cache..."; tldr --update >/dev/null 2>&1 || true; ok "tldr ready"
fi

# -- Done ----------------------------------------------------------------------
cat <<DONE

${green}${bold}All set!${reset}

Next steps:
  * Open ${bold}Ghostty${reset} (installed in /Applications). It already uses the
    MonaspiceNe Nerd Font + your colorscheme from ~/.config/ghostty/config.
  * Start a new shell:  ${bold}exec zsh${reset}
  * Switch colorscheme any time with:  ${bold}theme list${reset}  /  ${bold}theme <name>${reset}
  * If a glyph looks wrong, set your terminal font to "MonaspiceNe Nerd Font Mono".

Config locations:
  * zsh        ~/.config/zsh/{.zshenv,.zprofile,.zshrc,aliases.zsh,functions.zsh}
  * prompt     ~/.config/starship.toml
  * ghostty    ~/.config/ghostty/config
  * packages   ~/.config/Brewfile
DONE
