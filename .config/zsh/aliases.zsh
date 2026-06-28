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
# Safe force-push (refuses if it would clobber commits you haven't seen).
alias gpf='git push --force-with-lease'
# Publish the current branch and set its upstream in one go.
alias gpc='git push --set-upstream origin "$(git symbolic-ref --short HEAD)"'
# Switch to the repo's real default branch (reads origin/HEAD).
alias gswm='git switch "$(basename "$(git symbolic-ref --quiet refs/remotes/origin/HEAD || echo main)")"'
# Quick WIP checkpoint (skips hooks) and its undo (uncommit, keep changes staged).
alias gwip='git add -A && git commit --no-verify -m "WIP"'
alias gunwip='git reset --soft HEAD~1'
alias lg='lazygit'

# -- Python via uv (projects, venvs, tools) ------------------------------------
# uv is the single entry point: `uv init` a project, `uv add`/`uv remove` deps,
# `uv run` to run inside the project venv, `uv sync` to match the lockfile.
# Editor LSPs (basedpyright, ruff) are installed once with `uv tool install`.
alias uvr='uv run'               # run a command in the project venv
alias uva='uv add'               # add a dependency
alias uvrm='uv remove'           # remove a dependency
alias uvs='uv sync'              # sync the venv to uv.lock
alias uvl='uv lock'              # update the lockfile
alias uvpy='uv python'           # manage Python versions (install/list/pin)
alias uvt='uv tool'              # manage global tools (install/list/upgrade)
alias venv='uv venv'             # create a .venv in the current dir
# `py` runs the project venv's python in a uv project, else system python3 (fn
# in functions.zsh so arguments like `py script.py` are passed through correctly).

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
