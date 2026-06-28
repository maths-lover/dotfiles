# ~/.config/zsh/functions.zsh - sourced from .zshrc

# mkcd - make a directory (and parents) then cd into it
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# up - go up N directories (default 1):  up 3
up() {
  local n="${1:-1}" p=""
  while ((n-- > 0)); do p+="../"; done
  cd -- "$p" || return
}

# extract - universal archive extractor:  extract foo.tar.gz
extract() {
  if [[ -z "$1" || ! -f "$1" ]]; then
    echo "usage: extract <archive>"; return 1
  fi
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1"   ;;
    *.tar.gz|*.tgz)   tar xzf "$1"   ;;
    *.tar.xz)         tar xJf "$1"   ;;
    *.tar)            tar xf  "$1"   ;;
    *.bz2)            bunzip2 "$1"   ;;
    *.gz)             gunzip  "$1"   ;;
    *.zip)            unzip   "$1"   ;;
    *.rar)            unrar x "$1"   ;;
    *.7z)             7z x    "$1"   ;;
    *.Z)              uncompress "$1";;
    *) echo "extract: don't know how to extract '$1'"; return 1 ;;
  esac
}

# lsarchive - peek inside an archive without extracting:  lsarchive foo.tar.zst
lsarchive() {
  if [[ -z "$1" || ! -f "$1" ]]; then echo "usage: lsarchive <archive>"; return 1; fi
  case "${1:l}" in
    *.tar.bz2|*.tbz2|*.tar.bz) tar -tjf "$1" ;;
    *.tar.gz|*.tgz)            tar -tzf "$1" ;;
    *.tar.xz|*.txz)            tar -tJf "$1" ;;
    *.tar.zst|*.tzst)          tar --zstd -tf "$1" ;;
    *.tar)                     tar -tf "$1" ;;
    *.zip|*.jar|*.war|*.ear)   unzip -l "$1" ;;
    *.rar)                     unrar l "$1" ;;
    *.7z)                      7z l "$1" ;;
    *.gz)                      gzip -l "$1" ;;
    *.xz)                      xz -l "$1" ;;
    *) echo "lsarchive: don't know how to list '$1'"; return 1 ;;
  esac
}

# archive - create a compressed archive; format inferred from the name:
#   archive out.tar.zst src/ notes.md      # zstd: fast + good ratio
#   archive backup.tar.xz project/         # xz: best ratio
#   archive bundle.zip a b c               # zip
archive() {
  if (( $# < 2 )); then
    echo "usage: archive <name.{tar.gz,tar.bz2,tar.xz,tar.zst,tar,zip,7z}> <files...>"
    return 1
  fi
  local name="$1"; shift
  local f
  for f in "$@"; do [[ -e "$f" ]] || { echo "archive: '$f' not found"; return 1; }; done
  case "${name:l}" in
    *.tar.gz|*.tgz)   tar -czf  "$name" "$@" ;;
    *.tar.bz2|*.tbz2) tar -cjf  "$name" "$@" ;;
    *.tar.xz|*.txz)   tar -cJf  "$name" "$@" ;;
    *.tar.zst|*.tzst) tar --zstd -cf "$name" "$@" ;;
    *.tar)            tar -cf   "$name" "$@" ;;
    *.zip)            zip -r -9 "$name" "$@" ;;
    *.7z)             7z a -mx=9 "$name" "$@" ;;
    *) echo "archive: unsupported extension for '$name'"; return 1 ;;
  esac && { echo "created: $name"; ls -lh -- "$name"; }
}

# fcd - fuzzy-find a directory (under cwd) and cd into it
fcd() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf +m \
        --preview 'eza --tree --color=always --level=2 {}') && cd -- "$dir"
}

# fe - fuzzy-find a file and open it in $EDITOR
fe() {
  local file
  file=$(fd --type f --hidden --exclude .git | fzf +m \
        --preview 'bat --color=always --style=numbers {}') && ${EDITOR} -- "$file"
}

# fkill - fuzzy-pick a process and kill it
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m --header='[kill:select process]' | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -"${1:-9}"
}

# fbr - fuzzy-checkout a git branch
fbr() {
  local branch
  branch=$(git branch --all | grep -v HEAD | sed 's/^[* ]*//;s#remotes/[^/]*/##' \
           | sort -u | fzf) && git switch "$(echo "$branch" | sed 's#^remotes/[^/]*/##')"
}

# fglog - browse the commit log with fzf; preview shows the diff, Enter pages it.
fglog() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" \
    | fzf --ansi --no-sort --reverse --tiebreak=index \
        --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | head -1 | xargs -I% git show --color=always %' \
        --bind 'enter:execute(grep -o "[a-f0-9]\{7,\}" <<< {} | head -1 | xargs -I% git show --color=always % | less -R)'
}

# fgst - browse stashes with fzf; preview the diff, print the chosen stash.
fgst() {
  local stash
  stash=$(git stash list \
          | fzf --reverse --preview 'cut -d: -f1 <<< {} | xargs git stash show -p --color=always' \
          | cut -d: -f1)
  [[ -n "$stash" ]] && git stash show -p "$stash"
}

# gclone - clone a repo and cd into it
gclone() {
  git clone "$1" && cd -- "$(basename "${1%.git}")"
}

# py - run python from the project's uv venv when in a uv project (or an active
# venv), otherwise the system python3. Args pass through:  py, py script.py, etc.
py() {
  if [[ -n $VIRTUAL_ENV || -f pyproject.toml || -f uv.lock || -f .python-version ]]; then
    uv run python "$@"
  else
    python3 "$@"
  fi
}

# zj - fuzzy project switcher: pick a zoxide dir, then attach-or-create a named
# zellij session running the `coding` layout. The core "jump between projects"
# move. Bound to Ctrl-f (see .zshrc); also runnable as `zj`.
zj() {
  local dir name
  dir=$(zoxide query -l | fzf --reverse --height=60% --border \
        --header='jump to project -> zellij session' \
        --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null') || return
  [[ -z $dir ]] && return
  name=${dir:t}; name=${name//[._: ]/-}          # session name from dir basename
  if [[ -n $ZELLIJ ]]; then
    print -r -- "Already inside zellij - press Ctrl-o then w to switch sessions."
    return 1
  fi
  builtin cd -- "$dir" || return
  if zellij list-sessions -ns 2>/dev/null | grep -qx -- "$name"; then
    zellij attach -- "$name"                      # resurrect/attach existing
  else
    zellij --layout coding --session "$name"      # create with the coding layout
  fi
}

# nvp - open a project in its OWN Neovide window (one window per project). Pick a
# dir from zoxide history; Neovide opens rooted there so its LSP/finders scope to
# it. Use this to work on several projects side by side as separate windows.
nvp() {
  local dir
  dir=$(zoxide query -l | fzf --reverse --height=60% --border \
        --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null' \
        --header 'open project in Neovide (new window)') || return
  [[ -n $dir ]] && (builtin cd -- "$dir" && neovide .)
}

# ff - find files by NAME (fd). Pattern is a regex; add a path to search elsewhere.
#   ff config                 # files matching 'config' under cwd
#   ff '\.lua$' ~/.config     # lua files under ~/.config (outside cwd)
ff() { fd --type f --hidden --follow --exclude .git "$@" }

# fdir - find directories by NAME (fd). `fd` itself is the tool; this is the
# dir-only shortcut. Add a path to search outside cwd.
#   fdir src                  # dirs matching 'src' under cwd
#   fdir node_modules ~/code  # under ~/code
fdir() { fd --type d --hidden --follow --exclude .git "$@" }

# frg - live grep file CONTENTS with ripgrep, pick a match, open it in $EDITOR at
# the line. Type to refine; results reload as you type. Optional initial query.
#   frg               # start empty, type to search
#   frg TODO          # start with 'TODO'
frg() {
  local rg='rg --column --line-number --no-heading --color=always --smart-case'
  local out
  out=$(
    fzf --ansi --disabled --query "${1:-}" \
        --bind "start:reload:$rg {q} || true" \
        --bind "change:reload:sleep 0.1; $rg {q} || true" \
        --delimiter : \
        --preview 'bat --color=always --highlight-line {2} {1} 2>/dev/null' \
        --preview-window 'right,60%,+{2}-/2' \
        --header 'live grep -> open in editor at line'
  ) || return
  local file=${out%%:*}
  local line=${${out#*:}%%:*}
  [[ -n $file ]] && ${EDITOR} +"${line:-1}" -- "$file"
}

# _xkcd_print - fetch a comic and emit title + inline image + alt to stdout.
# $1 = selector (random|latest|N); remaining args are passed to chafa (the async
# path forces --format kitty since a background job has no tty to auto-detect).
_xkcd_print() {
  command -v jq >/dev/null && command -v chafa >/dev/null || {
    print -u2 "xkcd: needs jq and chafa"; return 1
  }
  local sel="${1:-random}"; shift
  local meta
  if [[ $sel == latest ]]; then
    meta=$(curl -fsm5 https://xkcd.com/info.0.json) || return 1
  elif [[ $sel == random ]]; then
    local latest
    latest=$(curl -fsm5 https://xkcd.com/info.0.json | jq -r .num) || return 1
    meta=$(curl -fsm5 "https://xkcd.com/$(( RANDOM % latest + 1 ))/info.0.json") || return 1
  else
    meta=$(curl -fsm5 "https://xkcd.com/${sel}/info.0.json") || return 1
  fi
  [[ -n $meta ]] || return 1
  local img title alt n
  img=$(jq -r .img  <<<"$meta"); title=$(jq -r .title <<<"$meta")
  alt=$(jq -r .alt  <<<"$meta"); n=$(jq -r .num   <<<"$meta")
  local tmp; tmp=$(mktemp) || return 1
  curl -fsm10 -o "$tmp" "$img" || { rm -f "$tmp"; return 1; }
  # print -r (raw) so a title/alt containing % or \ is never mis-rendered.
  local cyan=$'\e[1;36m' dim=$'\e[90m' rst=$'\e[0m'
  print -r -- "${cyan}xkcd #${n}: ${title}${rst}"
  chafa "$@" --size "${XKCD_SIZE:-60x24}" "$tmp"
  print -r -- "${dim}${alt}${rst}"
  rm -f "$tmp"
}

# xkcd - show a comic inline. In bare Ghostty chafa auto-detects kitty graphics
# (a real image); inside zellij (which cannot pass the graphics protocol) it
# falls back to ANSI block art. Needs curl, jq, chafa.
#   xkcd            # random comic
#   xkcd 327        # comic #327
#   xkcd latest     # newest comic
# Tune the size with XKCD_SIZE (default 60x24), e.g.  XKCD_SIZE=80x30 xkcd
xkcd() {
  if [[ -n ${ZELLIJ:-} ]]; then
    _xkcd_print "${1:-random}" --format symbols
  else
    _xkcd_print "${1:-random}"
  fi
}

# _xkcd_ready - ZLE fd-watcher callback: the background render has finished, so
# paint the comic above the prompt. `zle -I` tells ZLE we produced output, so it
# tidies up and redraws the prompt (and any typed text) below the image.
_xkcd_ready() {
  local fd=$1
  zle -F "$fd"          # unregister this watcher (fires once)
  exec {fd}<&-          # close the fd
  if [[ -s ${_XKCD_FILE:-} ]]; then
    zle -I
    print -r -- ""
    command cat -- "$_XKCD_FILE"
  fi
  command rm -f -- "${_XKCD_FILE:-}"
  unset _XKCD_FILE _XKCD_FD
}

# _xkcd_async_start - kick off a random comic in the BACKGROUND so the shell is
# instant; it is painted above the prompt the moment it is ready (see above).
# Bare Ghostty gets a real kitty-graphics image; zellij (no graphics protocol)
# gets ANSI block art, shown only in the FIRST pane of a session so the 3-pane
# `coding` layout does not show it thrice. Interactive only, never over SSH/tmux;
# silent if offline. Disable with XKCD_NO_GREETING=1 in local.zsh.
_xkcd_async_start() {
  [[ -o interactive ]] || return
  [[ -z ${XKCD_NO_GREETING:-} ]] || return
  [[ -z ${SSH_TTY:-} && -z ${SSH_CONNECTION:-} ]] || return
  command -v chafa >/dev/null && command -v jq >/dev/null || return

  local fmt
  if [[ -n ${ZELLIJ:-} ]]; then
    # Once per zellij session (marker keyed by session name).
    local marker="${TMPDIR:-/tmp}/.xkcd-zellij-${ZELLIJ_SESSION_NAME:-default}"
    [[ -e $marker ]] && return
    : >| "$marker"
    fmt=symbols
  elif [[ ${TERM_PROGRAM:-} == ghostty || -n ${GHOSTTY_RESOURCES_DIR:-} ]]; then
    [[ -z ${TMUX:-} ]] || return     # tmux also eats the graphics protocol
    fmt=kitty
  else
    return
  fi

  _XKCD_FILE=$(mktemp -t xkcd.XXXXXX) || return
  # Render to the file in a background job (no tty there, so the format is forced
  # explicitly). The process-substitution fd hits EOF when the job ends; ZLE then
  # calls _xkcd_ready to paint it above the prompt.
  exec {_XKCD_FD}< <(_xkcd_print random --format "$fmt" >| "$_XKCD_FILE" 2>/dev/null)
  zle -F "$_XKCD_FD" _xkcd_ready
}
