# ~/.config/zsh/.zprofile  (ZDOTDIR)
# Read for LOGIN shells. Put environment that should be set once per login here.

# ── Homebrew (Apple Silicon) ──────────────────────────────────────────────────
# Sets PATH, MANPATH, INFOPATH, HOMEBREW_PREFIX, etc.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ── Personal bin ──────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── OpenJDK (keg-only; needed on PATH for neovim's jdtls Java LSP) ─────────────
if [[ -d "$HOMEBREW_PREFIX/opt/openjdk/bin" ]]; then
  export PATH="$HOMEBREW_PREFIX/opt/openjdk/bin:$PATH"
fi
