# ~/.config/zsh/aliases.zsh - sourced from .zshrc

# -- Listing (eza) -------------------------------------------------------------
alias ls='eza --group-directories-first --icons=auto'
alias l='eza -lh --group-directories-first --icons=auto --git'
alias ll='eza -lah --group-directories-first --icons=auto --git'
alias la='eza -a --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
alias lt3='eza --tree --level=3 --icons=auto --group-directories-first'

# -- Viewing (bat) -------------------------------------------------------------
# bat auto-detects pipes and behaves like cat, so this is safe in scripts.
# Bypass with `command cat` or `\cat` if ever needed.
alias cat='bat --paging=never'
alias catp='bat --paging=never --style=plain'   # no line numbers/borders

# -- Editor (neovim) -----------------------------------------------------------
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias vimdiff='nvim -d'

# -- Git -----------------------------------------------------------------------
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gsw='git switch'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch --all --prune'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all'
alias lg='lazygit'

# -- Modern tool shortcuts (own names; no incompatible shadowing) ---------------
alias top='btop'                 # btop is interactive; safe at the prompt
alias cls='clear'
alias reload='exec zsh'          # reload the shell
alias zshrc='${EDITOR} "$ZDOTDIR/.zshrc"'
alias zshreload='source "$ZDOTDIR/.zshrc"'

# -- Safety / convenience ------------------------------------------------------
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'
alias df='df -h'
alias path='print -l -- $path'
alias ip='ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1'
alias myip='curl -s https://ifconfig.me; echo'
alias ports='lsof -iTCP -sTCP:LISTEN -nP'

# -- Eza tree alias for `tree` if you have the muscle memory --------------------
alias tree='eza --tree --icons=auto --group-directories-first'

# -- zellij (multiplexer / session management) ---------------------------------
alias zjl='zellij list-sessions'
alias zja='zellij attach'
alias zjk='zellij kill-session'
alias zjka='zellij kill-all-sessions'
alias zjhelp='bat --style=plain "$XDG_CONFIG_HOME/zellij/CHEATSHEET.md" 2>/dev/null || cat "$XDG_CONFIG_HOME/zellij/CHEATSHEET.md"'
# `zj` (function in functions.zsh) is the fuzzy project session switcher.
