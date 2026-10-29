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
  github-dark    "GitHub Dark Default"
  tokyonight     "TokyoNight Night"
  dracula        "Dracula"
  gruvbox        "Gruvbox Dark Hard"
  cyberpunk      "Cyberpunk"
  homebrew       "Homebrew"
  matrix         "Matrix"
  # -- green-on-black (keep a vivid ANSI palette; see themes/Green Terminal) --
  green          "Green Terminal"
  hipster-green  "Hipster Green"
  phala          "Phala Green Dark"
  seedflip       "SeedFlip Phosphor"
  phosphor       "Green Phosphor CRT"
  rosepine       "Rose Pine"
  rosepine-moon  "Rose Pine Moon"
  # -- light --
  gruvbox-light  "Gruvbox Light Hard"
  latte          "Catppuccin Latte"
  github-light   "GitHub Light Default"
  tokyonight-day "TokyoNight Day"
  rosepine-dawn  "Rose Pine Dawn"
)
typeset -ga THEME_DARK=(github-dark tokyonight dracula gruvbox cyberpunk homebrew matrix green hipster-green phala seedflip phosphor rosepine rosepine-moon)
typeset -ga THEME_LIGHT=(gruvbox-light latte github-light tokyonight-day rosepine-dawn)
: ${THEME_DEFAULT_DARK:=github-dark}
: ${THEME_DEFAULT_LIGHT:=github-light}

# Per-theme window opacity, written to `background-opacity` in the Ghostty
# config on switch (opacity can't be changed live via OSC - reload Ghostty with
# Cmd+Shift+, or open a new window). Themes not listed use the default.
typeset -gA THEME_OPACITY=(
  green 0.9  hipster-green 0.9  phala 0.9  seedflip 0.9  phosphor 0.9
  homebrew 0.9  matrix 0.9
)
: ${THEME_OPACITY_DEFAULT:=0.96}

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

# Inside zellij, OSC 4/10/11/12 never reach Ghostty: zellij stores them as
# per-PANE overrides (zellij-server/src/panes/grid.rs, osc_dispatch), so the
# window, other panes and zellij's own bar don't change. There the switch has
# to go through the Ghostty config + a reload instead. These reset codes drop
# any stale per-pane overrides so the pane follows the host palette again.
_theme_reset_osc() { printf '\e]104\a\e]110\a\e]111\a\e]112\a' }
_theme_in_zellij() { (( ${+ZELLIJ} )) }

# Ask Ghostty to reload its config (re-applies theme + opacity to EVERY window,
# zellij panes included - its "ansi" theme follows the palette). macOS Ghostty
# has no CLI/IPC for this, so send its reload_config keybind (Cmd+Shift+,) via
# AppleScript. One-time setup: System Settings > Privacy & Security >
# Accessibility > enable Ghostty. Returns 1 if that isn't granted.
_theme_ghostty_reload() {
  [[ $OSTYPE == darwin* ]] || return 1
  osascript -e 'tell application "System Events" to tell process "Ghostty" to keystroke "," using {command down, shift down}' >/dev/null 2>&1
}

# Resolve a (possibly aliased) name to a theme file path.
_theme_file() {
  local name=${THEME_ALIASES[$1]:-$1}
  if   [[ -f "$_THEME_USRDIR/$name" ]]; then print -r -- "$_THEME_USRDIR/$name"
  elif [[ -f "$_THEME_SYSDIR/$name" ]]; then print -r -- "$_THEME_SYSDIR/$name"
  else return 1; fi
}

# Print a swatch sheet so you can judge a theme on real content: default
# fg/bg, the 16 ANSI colors as both text and blocks, text attributes, a
# truecolor strip (24-bit colors ignore the palette - TUIs like Claude Code use
# them heavily) and a mock TUI line.
_theme_demo() {
  local i names=(blk red grn yel blu mag cyn wht)
  print -P "\n%B  default text%b  this is the foreground on the background. %F{8}dim/comment text (color 8)%f"
  print -n "  normal  "; for i in {0..7};  do printf '\e[3%dm %-4s\e[0m' $i $names[i+1]; done; echo
  print -n "  bright  "; for i in {0..7};  do printf '\e[9%dm %-4s\e[0m' $i $names[i+1]; done; echo
  print -n "  blocks  "; for i in {0..7};  do printf '\e[4%dm    \e[0m' $i; done
  print -n " "; for i in {0..7}; do printf '\e[10%dm    \e[0m' $i; done; echo
  printf '  attrs   \e[1mbold\e[0m  \e[2mdim\e[0m  \e[3mitalic\e[0m  \e[4munderline\e[0m  \e[7mreverse\e[0m  \e[9mstrike\e[0m\n'
  print -n "  24-bit  "; for i in {0..47}; do printf '\e[48;2;%d;%d;%dm \e[0m' $((255-i*5)) $((i*5)) $((128+i*2)); done; echo
  printf '  tui     \e[1;32m✓\e[0m Edit(file.zsh)  \e[33m⚠ 2 warnings\e[0m  \e[31m✗ 1 error\e[0m  \e[34mhttps://link\e[0m  \e[35m@user\e[0m  \e[36m$ cmd --flag\e[0m  \e[90m(3s)\e[0m\n'
  printf '  diff    \e[32m+ added line\e[0m   \e[31m- removed line\e[0m   \e[33m~ modified\e[0m\n\n'
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
      print -P "%BTry%b    theme preview <name> - theme revert - theme demo - theme browse"
      print -P "Any Ghostty theme name also works, e.g.  theme \"Rose Pine\""
      return 0 ;;
    toggle)
      local cur=""; [[ -f $_THEME_STATE ]] && cur=$(<$_THEME_STATE)
      if (( ${THEME_LIGHT[(Ie)$cur]} )); then theme "$THEME_DEFAULT_DARK"
      else theme "$THEME_DEFAULT_LIGHT"; fi
      return ;;
    dark)  theme "$THEME_DEFAULT_DARK";  return ;;
    light) theme "$THEME_DEFAULT_LIGHT"; return ;;
    # -- previewing ------------------------------------------------------------
    demo|test) _theme_demo; return ;;             # swatch sheet for current colors
    browse)    ghostty +list-themes; return ;;    # Ghostty's own TUI theme browser
    preview|try)                                  # recolor THIS window only, no persist
      local pf
      if ! pf=$(_theme_file "$2"); then
        print -P "%F{red}theme:%f '$2' not found - try %Btheme browse%b"; return 1
      fi
      _theme_emit_osc "$pf"; _theme_demo
      print -P "  %F{8}preview only -%f %Btheme revert%b to undo, %Btheme $2%b to keep"
      _theme_in_zellij && print -P "  %F{8}(inside zellij only this pane recolors; zellij's bar follows once applied)%f"
      return ;;
    revert|undo)                                  # re-apply the saved theme
      local cur="" rf; [[ -f $_THEME_STATE ]] && cur=$(<$_THEME_STATE)
      if _theme_in_zellij; then _theme_reset_osc    # back to host palette
      elif [[ -n $cur ]] && rf=$(_theme_file "$cur"); then _theme_emit_osc "$rf"; fi
      print -P "%F{green}+%f reverted to %B${cur:-default}%b"; return ;;
  esac

  local name=${THEME_ALIASES[$cmd]:-$cmd} f
  if ! f=$(_theme_file "$cmd"); then
    print -P "%F{red}theme:%f '$cmd' not found - run %Btheme list%b"; return 1
  fi
  local need_reload=0
  if _theme_in_zellij; then                  # can't recolor live; see _theme_reset_osc
    _theme_reset_osc; need_reload=1
  else
    _theme_emit_osc "$f"                     # recolor current window now
  fi

  # Keep shell comments visible when switching between light/dark themes.
  local is_light=0
  if (( ${THEME_LIGHT[(Ie)$cmd]} )); then
    is_light=1
    (( $+ZSH_HIGHLIGHT_STYLES )) && ZSH_HIGHLIGHT_STYLES[comment]='fg=240,italic'
  else
    (( $+ZSH_HIGHLIGHT_STYLES )) && ZSH_HIGHLIGHT_STYLES[comment]='fg=245,italic'
  fi

  # Pick the starship palette (it re-reads config on every prompt draw, so
  # this applies on the next prompt): GitHub themes get their dedicated Primer
  # palettes; everything else falls back to the generic dark/light ANSI one.
  local scfg="$HOME/.config/starship.toml"
  if [[ -f $scfg ]]; then
    local pal
    case $cmd in
      github-dark)  pal=github-dark ;;
      github-light) pal=github-light ;;
      *) if (( is_light )); then pal=theme-light; else pal=theme-dark; fi ;;
    esac
    sed -i '' "s|^palette = '.*'|palette = '$pal'|" "${scfg:A}"
  fi

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
    local op=${THEME_OPACITY[$cmd]:-$THEME_OPACITY_DEFAULT} note=""
    if grep -q '^background-opacity = ' "$gcfg"; then
      if ! grep -q "^background-opacity = $op\$" "$gcfg"; then
        sed -i '' "s|^background-opacity = .*|background-opacity = $op|" "$gcfg"
        note="  opacity $op"; need_reload=1
      fi
    else
      print -r -- "background-opacity = $op" >> "$gcfg"; note="  opacity $op"; need_reload=1
    fi
  fi
  print -P "%F{green}+%f theme -> %B$cmd%b  %F{8}($name)$note%f"
  if (( need_reload )); then
    if _theme_ghostty_reload; then print -P "  %F{8}ghostty reloaded%f"
    else
      print -P "  %F{yellow}press Cmd+Shift+, in Ghostty to apply%f"
      print -P "  %F{8}(auto-reload: System Settings > Privacy & Security > Accessibility > enable Ghostty)%f"
    fi
  fi
}

# Tab-completion: friendly aliases + sub-commands.
_theme() { compadd -- ${(k)THEME_ALIASES} dark light toggle list preview revert demo browse }
compdef _theme theme 2>/dev/null
