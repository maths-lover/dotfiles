# ~/.config/zsh/theme.zsh - live colorscheme switcher for Ghostty + all CLI tools.
#
# Everything in this setup (starship, fzf, bat, eza) is configured with ANSI
# palette colors, so swapping the terminal's 16-color palette re-themes the whole
# stack at once. `theme` recolors the CURRENT window instantly via OSC escape
# sequences AND persists the choice to ~/.config/ghostty/config so new windows
# match too. Theme definitions are read straight from Ghostty's bundled themes,
# so any of its 200+ themes (light or dark) works.

# Friendly aliases -> exact Ghostty theme names (so you can skip quoting spaces).
typeset -gA THEME_ALIASES=(
  # -- dark --
  tokyonight     "TokyoNight Night"
  dracula        "Dracula"
  gruvbox        "Gruvbox Dark Hard"
  cyberpunk      "Cyberpunk"
  homebrew       "Homebrew"
  matrix         "Matrix"
  # -- light --
  gruvbox-light  "Gruvbox Light Hard"
  latte          "Catppuccin Latte"
  github-light   "GitHub Light Default"
  tokyonight-day "TokyoNight Day"
)
typeset -ga THEME_DARK=(tokyonight dracula gruvbox cyberpunk homebrew matrix)
typeset -ga THEME_LIGHT=(gruvbox-light latte github-light tokyonight-day)
: ${THEME_DEFAULT_DARK:=tokyonight}
: ${THEME_DEFAULT_LIGHT:=gruvbox-light}

_THEME_SYSDIR="/Applications/Ghostty.app/Contents/Resources/ghostty/themes"
_THEME_USRDIR="$HOME/.config/ghostty/themes"
_THEME_STATE="$HOME/.config/zsh/.active-theme"
_THEME_GCFG="$HOME/.config/ghostty/config"

# Emit OSC sequences from a Ghostty theme file to recolor the live terminal.
_theme_emit_osc() {
  local f=$1 line idx val
  while IFS= read -r line; do
    case $line in
      'palette = '*)
        val=${line#palette = }; idx=${val%%=*}; val=${val#*=}
        printf '\e]4;%s;%s\a' "$idx" "$val" ;;
      'background = '*)   printf '\e]11;%s\a' "${line#background = }" ;;
      'foreground = '*)   printf '\e]10;%s\a' "${line#foreground = }" ;;
      'cursor-color = '*) printf '\e]12;%s\a' "${line#cursor-color = }" ;;
    esac
  done < "$f"
}

# Resolve a (possibly aliased) name to a theme file path.
_theme_file() {
  local name=${THEME_ALIASES[$1]:-$1}
  if   [[ -f "$_THEME_USRDIR/$name" ]]; then print -r -- "$_THEME_USRDIR/$name"
  elif [[ -f "$_THEME_SYSDIR/$name" ]]; then print -r -- "$_THEME_SYSDIR/$name"
  else return 1; fi
}

theme() {
  local cmd=$1
  case $cmd in
    ''|list|-l|--list)
      local cur="(none)"; [[ -f $_THEME_STATE ]] && cur=$(<$_THEME_STATE)
      print -P "%B Current theme:%b %F{green}$cur%f\n"
      print -P "%F{green}* dark%f   ${THEME_DARK[*]}"
      print -P "%F{yellow}o light%f  ${THEME_LIGHT[*]}"
      print -P "\n%BUsage%b  theme <name> - theme dark - theme light - theme toggle"
      print -P "Any Ghostty theme name also works, e.g.  theme \"Rose Pine\""
      return 0 ;;
    toggle)
      local cur=""; [[ -f $_THEME_STATE ]] && cur=$(<$_THEME_STATE)
      if (( ${THEME_LIGHT[(Ie)$cur]} )); then theme "$THEME_DEFAULT_DARK"
      else theme "$THEME_DEFAULT_LIGHT"; fi
      return ;;
    dark)  theme "$THEME_DEFAULT_DARK";  return ;;
    light) theme "$THEME_DEFAULT_LIGHT"; return ;;
  esac

  local name=${THEME_ALIASES[$cmd]:-$cmd} f
  if ! f=$(_theme_file "$cmd"); then
    print -P "%F{red}theme:%f '$cmd' not found - run %Btheme list%b"; return 1
  fi
  _theme_emit_osc "$f"                       # recolor current window now
  print -r -- "$cmd" > "$_THEME_STATE"       # remember choice
  # Persist to Ghostty config so new windows / restarts match.
  # Resolve symlinks (${:A}) so we edit the real file in the dotfiles repo
  # instead of replacing the stow symlink with a regular file.
  local gcfg=${_THEME_GCFG:A}
  if [[ -f $gcfg ]]; then
    if grep -q '^theme = ' "$gcfg"; then
      sed -i '' "s|^theme = .*|theme = $name|" "$gcfg"
    else
      print -r -- "theme = $name" >> "$gcfg"
    fi
  fi
  print -P "%F{green}+%f theme -> %B$cmd%b  %F{8}($name)%f"
}

# Tab-completion: friendly aliases + sub-commands.
_theme() { compadd -- ${(k)THEME_ALIASES} dark light toggle list }
compdef _theme theme 2>/dev/null
