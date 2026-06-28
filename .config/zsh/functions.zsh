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
