# ~/.config/zsh/functions.zsh — sourced from .zshrc

# mkcd — make a directory (and parents) then cd into it
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# up — go up N directories (default 1):  up 3
up() {
  local n="${1:-1}" p=""
  while ((n-- > 0)); do p+="../"; done
  cd -- "$p" || return
}

# extract — universal archive extractor:  extract foo.tar.gz
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

# fcd — fuzzy-find a directory (under cwd) and cd into it
fcd() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf +m \
        --preview 'eza --tree --color=always --level=2 {}') && cd -- "$dir"
}

# fe — fuzzy-find a file and open it in $EDITOR
fe() {
  local file
  file=$(fd --type f --hidden --exclude .git | fzf +m \
        --preview 'bat --color=always --style=numbers {}') && ${EDITOR} -- "$file"
}

# fkill — fuzzy-pick a process and kill it
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m --header='[kill:select process]' | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -"${1:-9}"
}

# fbr — fuzzy-checkout a git branch
fbr() {
  local branch
  branch=$(git branch --all | grep -v HEAD | sed 's/^[* ]*//;s#remotes/[^/]*/##' \
           | sort -u | fzf) && git switch "$(echo "$branch" | sed 's#^remotes/[^/]*/##')"
}

# gclone — clone a repo and cd into it
gclone() {
  git clone "$1" && cd -- "$(basename "${1%.git}")"
}
