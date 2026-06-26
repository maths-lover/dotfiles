# ~/.config/zsh/.zshrc  (ZDOTDIR)
# Read for INTERACTIVE shells. This is where the fun lives.

# Fallback so plugin paths resolve even in non-login interactive shells.
export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY        # record timestamps
setopt INC_APPEND_HISTORY      # write as you go, not just on exit
setopt SHARE_HISTORY           # share across live sessions
setopt HIST_IGNORE_ALL_DUPS    # drop older duplicates
setopt HIST_IGNORE_SPACE       # leading space hides a command from history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY             # expand !! etc. onto the line before running

# ── Shell options ─────────────────────────────────────────────────────────────
setopt AUTO_CD                 # `foo/` instead of `cd foo/`
setopt AUTO_PUSHD              # cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB           # #, ~, ^ globbing
setopt GLOB_DOTS              # globs match dotfiles too
setopt INTERACTIVE_COMMENTS    # allow # comments in the prompt
setopt NO_BEEP

# ── Completion system ─────────────────────────────────────────────────────────
# Add extra completion dirs to fpath BEFORE compinit.
fpath=(
  "$HOMEBREW_PREFIX/share/zsh-completions"
  "$HOMEBREW_PREFIX/share/zsh/site-functions"
  $fpath
)

autoload -Uz compinit
ZCOMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
mkdir -p "${ZCOMPDUMP:h}"
# Only re-audit the dump once every 24h (faster startup the rest of the time).
if [[ -n "$ZCOMPDUMP"(#qN.mh+24) ]]; then
  compinit -d "$ZCOMPDUMP"
else
  compinit -C -d "$ZCOMPDUMP"
fi

# Completion styling
zstyle ':completion:*' menu no                          # let fzf-tab handle the menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'  # case-insensitive + fuzzy
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' group-name ''
# fzf-tab: preview directory contents with eza, file content with bat
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ -d $realpath ]] && eza -1 --color=always --icons $realpath || bat --color=always --style=numbers $realpath 2>/dev/null'
zstyle ':fzf-tab:*' fzf-flags --height=60% --layout=reverse --border
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group ',' '.'

# ── Vim mode ──────────────────────────────────────────────────────────────────
# Set before plugins so their widgets bind into the vi keymaps.
bindkey -v
export KEYTIMEOUT=1                                     # 10ms — snappy ESC, no lag

# History prefix-search on arrows (works in insert & normal mode)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -M viins '^[[A' up-line-or-beginning-search
bindkey -M viins '^[[B' down-line-or-beginning-search
bindkey -M vicmd '^[[A' up-line-or-beginning-search
bindkey -M vicmd '^[[B' down-line-or-beginning-search
bindkey -M vicmd 'k'    up-line-or-beginning-search     # vim-style history
bindkey -M vicmd 'j'    down-line-or-beginning-search

# Keep the handy emacs editing keys available in INSERT mode
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^Y' yank
bindkey -M viins '^P' up-line-or-beginning-search
bindkey -M viins '^N' down-line-or-beginning-search
bindkey -M viins '^?' backward-delete-char             # backspace past insert start
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^[[3~' delete-char
bindkey -M viins '^[[1;5C' forward-word                 # Ctrl+Right
bindkey -M viins '^[[1;5D' backward-word               # Ctrl+Left
for km in viins vicmd; do
  bindkey -M $km '^[[H' beginning-of-line               # Home
  bindkey -M $km '^[[F' end-of-line                     # End
done

# `v` in normal mode → edit the command line in $EDITOR (vim); also Ctrl-X Ctrl-E
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
bindkey -M viins '^X^E' edit-command-line

# Vim text objects: ci" di( ya{ etc. work on the command line
autoload -Uz select-bracketed select-quoted
zle -N select-bracketed
zle -N select-quoted
for km in viopp visual; do
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do bindkey -M $km "$c" select-bracketed; done
  for c in {a,i}${(s..)^:-\'\"\`}; do bindkey -M $km "$c" select-quoted; done
done

# vim-surround: ys/cs/ds (+ S in visual) for quotes/brackets
autoload -Uz surround
zle -N delete-surround surround
zle -N change-surround surround
zle -N add-surround surround
bindkey -M vicmd 'cs' change-surround
bindkey -M vicmd 'ds' delete-surround
bindkey -M vicmd 'ys' add-surround
bindkey -M visual 'S'  add-surround

# Cursor shape: block in NORMAL, beam in INSERT (chains with starship's hook)
autoload -Uz add-zle-hook-widget
_vi_cursor_select() {
  case $KEYMAP in
    vicmd) printf '\e[2 q' ;;                            # steady block
    *)     printf '\e[6 q' ;;                            # steady beam
  esac
}
_vi_cursor_init() { printf '\e[6 q' }                    # beam on each new prompt
add-zle-hook-widget keymap-select _vi_cursor_select
add-zle-hook-widget line-init     _vi_cursor_init

# ── fzf integration (keybindings + completion). Needs fzf >= 0.48. ────────────
# Sourced BEFORE fzf-tab on purpose: fzf binds <Tab> to its own completion, then
# fzf-tab (below) re-binds <Tab> and wins — so we keep fzf's Ctrl-R/Ctrl-T/Alt-C
# but get fzf-tab's nicer in-place completion menu on <Tab>.
command -v fzf >/dev/null && source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
# Colors use ANSI palette indices (0-15) + -1 (terminal default) so fzf follows
# whatever theme is active — see `theme`. 2=green 4=blue 5=magenta 6=cyan 8=gray.
export FZF_DEFAULT_OPTS="
  --height 60% --layout reverse --border --info inline
  --preview-window 'right:55%:wrap'
  --color=fg:-1,bg:-1,hl:2
  --color=fg+:-1,bg+:8,hl+:10
  --color=info:4,prompt:2,pointer:5,marker:6,spinner:6,header:4
  --color=border:8,gutter:-1"
export FZF_CTRL_T_OPTS="--preview '[[ -d {} ]] && eza --tree --color=always {} || bat --color=always --style=numbers {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {}'"

# ── Plugins (order matters!) ──────────────────────────────────────────────────
# 1) fzf-tab — AFTER compinit & AFTER fzf (owns <Tab>), BEFORE widget-wrappers
[[ -f "$ZDOTDIR/plugins/fzf-tab/fzf-tab.plugin.zsh" ]] && \
  source "$ZDOTDIR/plugins/fzf-tab/fzf-tab.plugin.zsh"

# 2) autosuggestions
[[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'

# 3) syntax highlighting — MUST be sourced last
[[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ── Tool integrations ─────────────────────────────────────────────────────────
# zoxide — smarter cd (provides `z` and `zi`)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# bat theme — "ansi" makes bat use the terminal's 16-color palette, so its
# syntax highlighting follows the active theme automatically (see `theme`).
export BAT_THEME="ansi"

# eza colors — ANSI SGR codes (3x/9x) so file/permission colors also follow the
# active theme. 34=dir 32=exec 36=symlink 33/31/32=read/write/exec perms 90=meta.
export EZA_COLORS="da=90:di=34:ex=32:ln=36:ur=33:uw=31:ux=32:ue=32:gr=33:gw=31:gx=32:tr=33:tw=31:tx=32:su=35:sf=35:xa=90:lp=36:cc=35:sn=32:sb=32:uu=33:gu=33"

# ── Colorscheme switcher (theme <name> | dark | light | toggle | list) ────────
[[ -f "$ZDOTDIR/theme.zsh" ]] && source "$ZDOTDIR/theme.zsh"

# ── Aliases & functions ───────────────────────────────────────────────────────
[[ -f "$ZDOTDIR/aliases.zsh" ]]   && source "$ZDOTDIR/aliases.zsh"
[[ -f "$ZDOTDIR/functions.zsh" ]] && source "$ZDOTDIR/functions.zsh"

# ── Live RAM% for the prompt's color-shifting gauge ───────────────────────────
# Computed once per prompt and exported so starship's custom.ram_* modules
# (green→amber→red) can read it without each recomputing. ~2ms via vm_stat.
_starship_ram_pct() {
  local total
  total=$(sysctl -n hw.memsize 2>/dev/null) || return
  export STARSHIP_RAM_PCT=$(vm_stat 2>/dev/null | awk -v total="$total" '
    /page size of/          {ps=$8}
    /Pages active/          {gsub(/\./,"",$3); a=$3}
    /Pages wired down/      {gsub(/\./,"",$4); w=$4}
    /occupied by compressor/{gsub(/\./,"",$5); c=$5}
    END {if (total>0 && ps>0) printf "%d", ((a+w+c)*ps/total)*100; else print 0}')
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _starship_ram_pct

# ── Prompt (must be last so it isn't clobbered) ───────────────────────────────
command -v starship >/dev/null && eval "$(starship init zsh)"

# ── Local machine overrides (not tracked) ─────────────────────────────────────
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"
