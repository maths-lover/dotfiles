# ~/.config/zsh/font.zsh - quick font switcher for Ghostty (try fonts fast).
#
# Swaps the font-family lines in ghostty/config in place and remembers the
# choice. Ghostty has no live-reload from the shell, so after `font <name>`
# press ⌘⇧, in Ghostty (reload_config) to see it. Mirrors the `theme` switcher:
# resolves the Stow symlink so it edits the real repo file. All fonts below are
# Nerd Fonts (needed for the starship prompt glyphs).

typeset -gA FONT_FAMILIES=(
  # -- Monaspace cuts (font-monaspice-nerd-font) --
  neon      "MonaspiceNe Nerd Font Mono"
  argon     "MonaspiceAr Nerd Font Mono"
  xenon     "MonaspiceXe Nerd Font Mono"
  radon     "MonaspiceRn Nerd Font Mono"
  krypton   "MonaspiceKr Nerd Font Mono"
  # -- other crisp Nerd Fonts --
  jetbrains "JetBrainsMono Nerd Font Mono"
  maple     "Maple Mono NF"
  iosevka   "Iosevka Nerd Font Mono"
  geist     "GeistMono Nerd Font Mono"
  commit    "CommitMono Nerd Font Mono"
)
typeset -ga FONT_ORDER=(neon argon xenon radon krypton jetbrains maple iosevka geist commit)

_FONT_GCFG="$HOME/.config/ghostty/config"
_FONT_STATE="$HOME/.config/zsh/.active-font"

font() {
  local name=$1
  case $name in
    ''|list|-l|--list)
      local cur=neon; [[ -f $_FONT_STATE ]] && cur=$(<$_FONT_STATE)
      print -P "%B Font:%b %F{green}$cur%f  %F{8}(${FONT_FAMILIES[$cur]})%f"
      print -P "%BMonaspace%b  neon argon xenon radon krypton"
      print -P "%BOthers%b     jetbrains maple iosevka geist commit"
      print -P "%BUsage%b  font <name> | font next   then press %B\u2318\u21e7,%b in Ghostty to reload"
      return 0 ;;
    next)
      local cur=neon; [[ -f $_FONT_STATE ]] && cur=$(<$_FONT_STATE)
      local i=${FONT_ORDER[(Ie)$cur]}; (( i = i % ${#FONT_ORDER} + 1 ))
      name=${FONT_ORDER[i]} ;;
  esac

  local fam=${FONT_FAMILIES[$name]}
  [[ -n $fam ]] || { print -P "%F{red}font:%f '$name' - run %Bfont list%b"; return 1 }

  # Italic/bold faces: Monaspace uses its flourish cuts (Radon italic, Xenon
  # bold); every other font uses its own faces.
  local ital bold
  case $name in
    neon|argon|xenon|radon|krypton)
      ital="MonaspiceRn Nerd Font Mono"; bold="MonaspiceXe Nerd Font Mono" ;;
    *) ital=$fam; bold=$fam ;;
  esac

  # Resolve symlinks (${:A}) so we edit the real repo file, not the Stow symlink.
  local gcfg=${_FONT_GCFG:A}
  [[ -f $gcfg ]] || { print -P "%F{red}font:%f $gcfg missing"; return 1 }
  sed -i '' \
    -e "s|^font-family = .*|font-family = \"$fam\"|" \
    -e "s|^font-family-italic = .*|font-family-italic = \"$ital\"|" \
    -e "s|^font-family-bold = .*|font-family-bold = \"$bold\"|" \
    -e "s|^font-family-bold-italic = .*|font-family-bold-italic = \"$ital\"|" \
    "$gcfg"
  print -r -- "$name" > "$_FONT_STATE"
  print -P "%F{green}+%f font -> %B$name%b  %F{8}($fam)%f"
  print -P "  press %B\u2318\u21e7,%b in Ghostty to reload"
}

# Tab-completion: friendly names + sub-commands.
_font() { compadd -- ${(k)FONT_FAMILIES} next list }
compdef _font font 2>/dev/null
