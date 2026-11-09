#!/usr/bin/env bash
# rice.sh - install / apply / uninstall the macOS desktop rice.
#
#   rice.sh install     brew packages, snapshot current settings, stow configs, start services, apply
#   rice.sh apply [t]   re-render everything from the active `theme` (or theme t)
#   rice.sh uninstall   stop services, restore the snapshot, remove rendered files, unstow
#   rice.sh purge       uninstall + brew uninstall every rice package + delete state
#   rice.sh status      what is installed / running / applied (incl. wallpaper per Space)
#   rice.sh wallpapers [smooth|pixel|all]   render the wallpaper flavours and open them in Preview
#   rice.sh style [smooth|pixel|shuffle|shuffle-pixel|<flavours>]  pick the wallpaper set for every Space (and apply it)
#   rice.sh noctis-plugin   build + install the Noctis plugin that re-reads the rice's Noctis theme live (needs the .NET SDK)
#
# Design: the active Ghostty theme (chosen with the zsh `theme` command) is the
# single source of truth. ricelib.py turns it into palette.{sh,json,css} under
# ~/.local/state/rice, and every surface (SketchyBar, borders, wallpaper,
# Firefox, Discord/Vencord, Chrome, Übersicht, Noctis, macOS accent) is rendered from
# that. Nothing here edits the base dotfiles; `uninstall` restores every macOS
# setting from the snapshot taken on `install`.
set -euo pipefail

HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"   # dotfiles/rice/.config/rice
DOT="$(cd "$HERE/../../.." && pwd)"                                       # dotfiles/
STATE="$HOME/.local/state/rice"
SNAP="$STATE/snapshot.json"
LIB="$HERE/ricelib.py"
TPL="$HERE/templates"
BREWFILE="$HERE/Brewfile"
THEME_STATE="$HOME/.config/zsh/.active-theme"
UBER_WIDGETS="$HOME/Library/Application Support/Übersicht/widgets"
VENCORD="$HOME/Library/Application Support/Vencord"
FIREFOX="$HOME/Library/Application Support/Firefox"
NOCTIS="$HOME/Library/Application Support/Noctis"
NOCTIS_PACK="$NOCTIS/plugins/rice.theme"          # content pack: the theme as JSON (see noctis_apply)
NOCTIS_RELOADER="$NOCTIS/plugins/rice.reloader"   # dotnet plugin that re-reads the pack live (noctis/reloader)
# Wallpaper flavours (see wallpaper.py), handed out by Space number: Space 1 gets the
# first, Space 2 the second, ... wrapping around. Two ready-made sets: smooth line art
# and the same scenes as pixel art. `rice.sh style pixel|smooth|<list>` records the
# choice in $STATE/flavours; the env var RICE_WALLPAPER_FLAVOURS overrides both, e.g.
#   export RICE_WALLPAPER_FLAVOURS="contours peaks"   (in .zshrc, before `theme` runs)
FLAVOURS_SMOOTH="ridges contours strands waves peaks dunes orbits horizon constellation strata meteors"
FLAVOURS_PIXEL="pixel-ridges pixel-peaks pixel-waves pixel-contours pixel-strands pixel-dunes pixel-orbits pixel-horizon pixel-constellation pixel-strata pixel-meteors"
flavours_current() {
  if [[ -n ${RICE_WALLPAPER_FLAVOURS:-} ]]; then printf '%s' "$RICE_WALLPAPER_FLAVOURS"
  elif [[ -s $STATE/flavours ]]; then tr -s '\n' ' ' < "$STATE/flavours" | sed 's/ $//'
  else printf '%s' "$FLAVOURS_SMOOTH"; fi
}

bold=$(tput bold 2>/dev/null || true); reset=$(tput sgr0 2>/dev/null || true)
info() { printf '%s==>%s %s\n' "$bold" "$reset" "$*"; }
warn() { printf '%s  !%s %s\n' "$bold" "$reset" "$*" >&2; }
die()  { printf 'rice: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Resolve a theme alias (github-dark, green, ...) or full Ghostty name to its file,
# using the exact same lookup the zsh `theme` command uses.
theme_file() { zsh -c 'source ~/.config/zsh/theme.zsh >/dev/null 2>&1; _theme_file "$1"' _ "$1"; }

# Wallpaper: a different flavour of generated line art on EVERY Space of every
# display. Each picture is rendered once per theme + flavour + display size (at 2x
# the display's point size, i.e. its Retina backing size) and cached; then the whole
# plan is written straight into macOS's wallpaper store by ricelib (the only way to
# reach Spaces that are not currently on screen; see the notes there).
wallpapers_apply() {
  local name=$1
  # While the displays are asleep (or the screen saver runs) macOS reports no active
  # displays and yabai's queries come back truncated, so check them before trusting them.
  local displays=""
  if have uv && have yabai; then displays=$(yabai -m query --displays 2>/dev/null || true); fi
  if [[ -n $displays ]] && jq -e 'length > 0' <<< "$displays" >/dev/null 2>&1; then
    mkdir -p "$STATE/wallpapers"
    local flavours plan=() sidx didx suuid duuid w h flav png
    read -r -a flavours <<< "$(flavours_current)"
    while read -r sidx didx suuid duuid w h; do
      flav=${flavours[$(( (sidx - 1) % ${#flavours[@]} ))]}
      png="$STATE/wallpapers/${name}-${flav}-${w}x${h}.png"
      [[ -f $png ]] || { info "rendering $flav wallpaper ${w}x${h} for $name..."; uv run --quiet "$HERE/wallpaper.py" "$STATE/palette.json" "$png" "$w" "$h" "$flav"; }
      plan+=("$sidx $didx $flav $suuid $duuid $png")
    done < <(yabai -m query --spaces 2>/dev/null | jq -r --argjson d "$displays" \
      '.[] as $s | ($d[] | select(.index == $s.display)) as $dd
       | "\($s.index) \($dd.index) \($s.uuid) \($dd.uuid) \(($dd.frame.w*2)|floor) \(($dd.frame.h*2)|floor)"' 2>/dev/null)
    if (( ${#plan[@]} )); then
      printf '%s\n' "${plan[@]}" > "$STATE/wallpapers/plan.txt"      # what `status` shows
      python3 -IB "$LIB" wallpaper-store "$STATE" "$RICE_BG" < "$STATE/wallpapers/plan.txt"
    else
      warn "wallpaper: could not list spaces (displays asleep?); run 'rice.sh apply' again later"
    fi
  elif have uv && have yabai; then
    warn "wallpaper: yabai sees no active displays (asleep / screen saver?); skipped, run 'rice.sh apply' again later"
  fi
}

# ----------------------------------------------------------------------------- apply
# Noctis (music player): a *content pack* is a colour theme as plain JSON in Noctis's
# plugins folder; it needs no approval and Noctis derives everything the theme leaves
# out. Noctis only re-reads packs at startup, though, so the rice also ships a tiny
# plugin (noctis/reloader, installed by `rice.sh noctis-plugin`) that re-reads the
# pack the moment this function rewrites it. The first time the pack is created a
# `select-once.txt` marker asks that plugin to pick the Rice theme in Settings.
noctis_apply() {
  [[ -d $NOCTIS ]] || return 0
  local first=0; [[ -f $NOCTIS_PACK/plugin.json ]] || first=1
  mkdir -p "$NOCTIS_PACK/themes"
  # Render outside the pack, then rename into it: Noctis refuses a pack with a stray
  # file in it, and the reloader should see one finished file, not a half-written one.
  python3 -IB "$LIB" render "$TPL/noctis-theme.json" "$STATE/noctis-rice.json" "$STATE"
  mv -f "$STATE/noctis-rice.json" "$NOCTIS_PACK/themes/rice.json"
  cmp -s "$HERE/noctis/pack/plugin.json" "$NOCTIS_PACK/plugin.json" 2>/dev/null || cp -f "$HERE/noctis/pack/plugin.json" "$NOCTIS_PACK/plugin.json"
  (( first )) && : > "$NOCTIS_PACK/select-once.txt"
  if ! pgrep -xq Noctis; then info "noctis: Rice theme written (applies when Noctis starts)"
  elif [[ -f $NOCTIS_RELOADER/plugin.json ]]; then info "noctis: Rice theme written (the reloader plugin applies it live)"
  else info "noctis: Rice theme written; restart Noctis to see it, or 'rice.sh noctis-plugin' for live updates"; fi
}

# Build the reloader plugin against the installed Noctis.app and drop it into Noctis's
# plugins folder. Noctis only discovers plugins at startup, and a dotnet plugin needs a
# one-time approval under Settings > Plugins (it is code, unlike the pack).
noctis_plugin() {
  [[ -d /Applications/Noctis.app ]] || die "Noctis.app not found in /Applications"
  have dotnet || die "needs the .NET SDK: brew install dotnet"
  local src="$HERE/noctis/reloader" out="$STATE/noctis-reloader"
  info "Building the Noctis reloader plugin..."
  DOTNET_NOLOGO=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 dotnet build "$src" -c Release -o "$out/bin" --artifacts-path "$out/artifacts" -nologo -v quiet
  mkdir -p "$NOCTIS_RELOADER"
  cp -f "$out/bin/Rice.NoctisReloader.dll" "$out/bin/Rice.NoctisReloader.deps.json" "$src/plugin.json" "$NOCTIS_RELOADER/"
  info "noctis: reloader installed in $NOCTIS_RELOADER"
  if pgrep -xq Noctis; then warn "restart Noctis, then approve 'Rice theme reloader' under Settings > Plugins (once)"
  else info "approve 'Rice theme reloader' under Settings > Plugins when Noctis next starts (once)"; fi
}

apply() {
  local name=${1:-}
  [[ -n $name ]] || { [[ -f $THEME_STATE ]] && name=$(<"$THEME_STATE"); }
  [[ -n $name ]] || die "no active theme: run 'theme <name>' first or pass one"
  local file; file=$(theme_file "$name") || die "theme '$name' not found"
  mkdir -p "$STATE"
  python3 -IB "$LIB" palette "$name" "$file" "$STATE"
  # shellcheck disable=SC1091
  source "$STATE/palette.sh"
  info "rice -> $name ($RICE_APPEARANCE, accent $RICE_ACCENT)"

  # macOS appearance follows the theme's lightness.
  local dark=true; [[ $RICE_IS_LIGHT == 1 ]] && dark=false
  osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $dark" >/dev/null

  # System accent (nearest Apple preset; 4 = blue = the default, stored as "no key")
  # and highlight colour (any RGB). Apps pick these up when they next launch.
  read -r idx r g b < <(python3 -IB "$LIB" accent "$STATE")
  if [[ $idx == 4 ]]; then defaults delete -g AppleAccentColor 2>/dev/null || true
  else defaults write -g AppleAccentColor -int "$idx"; fi
  defaults write -g AppleHighlightColor -string "$r $g $b Other"

  # Chrome: enterprise policy that colours the frame. Read on next launch.
  defaults write com.google.Chrome BrowserThemeColor -string "$RICE_BG"

  # Bar and borders: live.
  pgrep -xq sketchybar && sketchybar --reload
  if pgrep -xq borders; then
    # `borders key=value` messages the running instance over a mach port. From a
    # launchd-started instance that call can hang when invoked outside a normal
    # login session, so give it 3s and otherwise restart the service (bordersrc
    # re-reads palette.sh).
    borders active_color="$RICE_ACCENT_0X" inactive_color="$RICE_BORDER_0X" >/dev/null 2>&1 &
    local bpid=$!; local i=0
    while kill -0 "$bpid" 2>/dev/null && (( i < 30 )); do sleep 0.1; i=$((i + 1)); done   # not ((i++)): returns 1 at 0 and trips set -e
    if kill -0 "$bpid" 2>/dev/null; then kill "$bpid" 2>/dev/null; wait "$bpid" 2>/dev/null || true; brew services restart borders >/dev/null 2>&1 || true; fi
  fi

  wallpapers_apply "$name"

  # Firefox: userChrome.css in every profile + the pref that enables it.
  if [[ -r $FIREFOX/profiles.ini ]]; then
    local rel path prof
    while IFS= read -r line; do
      case $line in
        IsRelative=*) rel=${line#IsRelative=} ;;
        Path=*) path=${line#Path=}; prof=$path; [[ ${rel:-1} == 1 ]] && prof="$FIREFOX/$path"
                if [[ -d $prof ]]; then
                  python3 -IB "$LIB" render "$TPL/firefox-userChrome.css" "$prof/chrome/userChrome.css" "$STATE"
                  grep -q 'RICE-MANAGED' "$prof/user.js" 2>/dev/null || \
                    printf '// RICE-MANAGED: let userChrome.css load (rice.sh)\nuser_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n' >> "$prof/user.js"
                fi ;;
      esac
    done < "$FIREFOX/profiles.ini"
    info "firefox: userChrome.css written (restart Firefox)"
  else
    warn "firefox: cannot read $FIREFOX (grant this terminal Full Disk Access, or run from Ghostty)"
  fi

  # Discord via Vencord: drop the theme and make it the enabled one.
  if [[ -d $VENCORD/themes ]]; then
    python3 -IB "$LIB" render "$TPL/vencord.theme.css" "$VENCORD/themes/rice.theme.css" "$STATE"
    if [[ -f $VENCORD/settings/settings.json ]] && have jq; then
      local tmp; tmp=$(mktemp)
      jq '.enabledThemes = ["rice.theme.css"]' "$VENCORD/settings/settings.json" > "$tmp" && mv "$tmp" "$VENCORD/settings/settings.json"
    fi
    info "discord: rice.theme.css enabled (Vencord reloads themes live)"
  fi

  # Übersicht widgets (hot-reloaded by the app).
  if [[ -d $UBER_WIDGETS ]]; then
    python3 -IB "$LIB" render "$TPL/ubersicht-clock.jsx" "$UBER_WIDGETS/rice-clock.jsx" "$STATE"
    python3 -IB "$LIB" render "$TPL/ubersicht-stats.jsx" "$UBER_WIDGETS/rice-stats.jsx" "$STATE"
  fi

  noctis_apply
  info "done"
}

# ----------------------------------------------------------------------------- install
install() {
  have brew || die "Homebrew required"
  info "Installing rice packages from $BREWFILE..."
  brew trust FelixKratz/formulae >/dev/null 2>&1 || true
  brew bundle --file "$BREWFILE"

  if [[ -f $SNAP ]]; then info "snapshot exists, keeping it: $SNAP"
  else info "Snapshotting current macOS settings..."; python3 -IB "$LIB" snapshot-take "$SNAP"; fi

  info "Stowing rice configs (~/.config/{rice,sketchybar,borders})..."
  stow -d "$DOT" -t "$HOME" --restow rice

  info "Dock: auto-hide, peeks out when the pointer hits the screen edge..."
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0.15       # seconds before it peeks out (Cmd+Ctrl+D toggles it)
  defaults write com.apple.dock autohide-time-modifier -float 0  # no slide animation
  defaults write com.apple.dock show-recents -bool false
  killall Dock

  info "Menu bar: auto-hide (SketchyBar takes its place)..."
  osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true' >/dev/null

  info "App icon map for the bar..."
  mkdir -p "$STATE/bin"
  curl -fsSL -o "$STATE/bin/icon_map.sh" https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/icon_map.sh \
    && chmod +x "$STATE/bin/icon_map.sh" || warn "icon_map.sh download failed; the bar shows app names only"

  info "Starting sketchybar + borders..."
  brew services start sketchybar >/dev/null
  brew services start borders >/dev/null

  info "Übersicht..."
  mkdir -p "$UBER_WIDGETS"
  # The app name has an umlaut, and `open -a` is picky about its Unicode form; the bundle id is not.
  open -b tracesOf.Uebersicht 2>/dev/null || open "/Applications/Übersicht.app" 2>/dev/null || warn "Übersicht did not launch"

  have yabai && { info "yabai: reserving space for the bar..."; yabai --restart-service; }
  if [[ -d /Applications/Noctis.app ]]; then
    if have dotnet; then noctis_plugin || warn "noctis: plugin build failed; the theme still applies when Noctis restarts"
    else warn "noctis: for live re-theming install the .NET SDK (brew install dotnet) and run 'rice.sh noctis-plugin'"; fi
  fi
  apply
  cat <<MSG

${bold}Rice installed.${reset}
  - Restart Firefox, Chrome and Discord to pick up their themes.
  - Accent colour applies to apps as they relaunch. For tinted app icons:
    System Settings > Appearance > Icon & widget style > Tinted (follows the accent).
  - Übersicht: grant it Accessibility only if you want widgets interactive (not needed).
  - Switch themes as always: ${bold}theme <name>${reset}. Undo everything: ${bold}rice.sh uninstall${reset}
MSG
}

# ----------------------------------------------------------------------------- uninstall / purge
remove_rendered() {
  local f
  if [[ -r $FIREFOX/profiles.ini ]]; then
    for f in "$FIREFOX"/Profiles/*/chrome/userChrome.css; do
      [[ -f $f ]] && grep -q 'RICE-MANAGED' "$f" && rm -f "$f"
    done
    for f in "$FIREFOX"/Profiles/*/user.js; do
      [[ -f $f ]] && grep -q 'RICE-MANAGED' "$f" && sed -i '' '/RICE-MANAGED/,+1d' "$f"
    done
  fi
  rm -f "$VENCORD/themes/rice.theme.css" "$UBER_WIDGETS"/rice-*.jsx
  rm -rf "$NOCTIS_PACK" "$NOCTIS_RELOADER" "$STATE/noctis-reloader"   # Noctis falls back to its default theme by itself
}

uninstall() {
  info "Stopping sketchybar + borders..."
  brew services stop sketchybar >/dev/null 2>&1 || true
  brew services stop borders >/dev/null 2>&1 || true
  pkill -f "bersicht.app/Contents/MacOS" 2>/dev/null || true
  if [[ -f $SNAP ]]; then
    info "Restoring macOS settings from $SNAP..."
    python3 -IB "$LIB" snapshot-restore "$SNAP"      # also swaps the wallpapers back
  else
    warn "no snapshot found; leaving macOS settings as they are"
  fi
  rm -rf "$STATE/wallpapers"
  info "Removing rendered theme files (Firefox, Vencord, Übersicht, Noctis)..."
  remove_rendered
  info "Unstowing rice configs..."
  stow -d "$DOT" -t "$HOME" -D rice 2>/dev/null || true
  have yabai && yabai --restart-service
  info "Rice uninstalled. Packages are still installed; 'rice.sh purge' removes them too."
}

purge() {
  uninstall
  info "Uninstalling rice packages..."
  brew uninstall --ignore-dependencies sketchybar borders wallpaper 2>/dev/null || true
  brew uninstall --cask ubersicht font-sketchybar-app-font 2>/dev/null || true
  brew untap FelixKratz/formulae 2>/dev/null || true
  rm -rf "$STATE" "$HOME/Library/Application Support/Übersicht"
  info "Purged. Discord's Vencord itself was left alone (it predates the rice)."
}

status() {
  printf 'theme:      %s\n' "$(cat "$THEME_STATE" 2>/dev/null || echo none)"
  printf 'applied:    %s\n' "$(jq -r .THEME "$STATE/palette.json" 2>/dev/null || echo never)"
  printf 'snapshot:   %s\n' "$([[ -f $SNAP ]] && echo "$SNAP" || echo none)"
  for p in sketchybar borders; do printf '%-11s %s\n' "$p:" "$(pgrep -xq $p && echo running || echo stopped)"; done
  printf 'ubersicht:  %s\n' "$(pgrep -fq 'bersicht.app/Contents/MacOS' && echo running || echo stopped)"
  printf 'stowed:     %s\n' "$([[ -L $HOME/.config/sketchybar ]] && echo yes || echo no)"
  printf 'style:      %s\n' "$(flavours_current)"
  [[ -d $NOCTIS ]] && printf 'noctis:     theme %s, reloader %s\n' "$([[ -f $NOCTIS_PACK/themes/rice.json ]] && echo written || echo missing)" "$([[ -f $NOCTIS_RELOADER/plugin.json ]] && echo installed || echo missing)"
  if [[ -f $STATE/wallpapers/plan.txt ]]; then
    printf 'wallpapers:\n'
    awk '{ printf "  space %s on display %s: %s\n", $1, $2, $3 }' "$STATE/wallpapers/plan.txt"
  fi
}

# Render every flavour for every connected display (cached, same files `apply` uses)
# and open them in Preview, so you can pick/reorder RICE_WALLPAPER_FLAVOURS by eye.
wallpapers() {
  [[ -f $STATE/palette.json ]] || die "nothing applied yet: run 'rice.sh apply' first"
  have uv && have yabai || die "needs uv and yabai"
  local set=${1:-all} list name files=() flav w h png
  case $set in
    smooth) list=$FLAVOURS_SMOOTH ;;
    pixel)  list=$FLAVOURS_PIXEL ;;
    all)    list="$FLAVOURS_SMOOTH $FLAVOURS_PIXEL" ;;
    *) die "wallpapers: expected smooth, pixel or all" ;;
  esac
  name=$(jq -r .THEME "$STATE/palette.json")
  mkdir -p "$STATE/wallpapers"
  while read -r w h; do
    for flav in $list; do
      png="$STATE/wallpapers/${name}-${flav}-${w}x${h}.png"
      [[ -f $png ]] || { info "rendering $flav ${w}x${h} for $name..."; uv run --quiet "$HERE/wallpaper.py" "$STATE/palette.json" "$png" "$w" "$h" "$flav"; }
      files+=("$png")
    done
  done < <(yabai -m query --displays | jq -r '.[] | "\((.frame.w*2)|floor) \((.frame.h*2)|floor)"')
  printf '%s\n' "${files[@]}"
  open -a Preview "${files[@]}"
}

# Choose which flavours the Spaces cycle through and re-apply the wallpapers only.
#   rice.sh style            show the current set
#   rice.sh style pixel      the pixel-art set       rice.sh style smooth   the line-art set
#   rice.sh style ridges pixel-peaks ...   any explicit list (names from wallpaper.py)
style() {
  if (( $# == 0 )); then printf '%s\n' "$(flavours_current)"; return; fi
  mkdir -p "$STATE"
  case $1 in
    smooth) printf '%s\n' "$FLAVOURS_SMOOTH" > "$STATE/flavours" ;;
    pixel)  printf '%s\n' "$FLAVOURS_PIXEL" > "$STATE/flavours" ;;
    shuffle|shuffle-pixel)   # a fresh random order of the set, so the Spaces get different scenes
      set_="$FLAVOURS_SMOOTH"; [[ $1 == shuffle-pixel ]] && set_="$FLAVOURS_PIXEL"
      tr ' ' '\n' <<< "$set_" | awk 'BEGIN{srand()} {print rand() "\t" $0}' | sort -n | cut -f2 | tr '\n' ' ' | sed 's/ $//' > "$STATE/flavours"
      echo >> "$STATE/flavours" ;;
    *)      printf '%s\n' "$*" > "$STATE/flavours" ;;
  esac
  [[ -n ${RICE_WALLPAPER_FLAVOURS:-} ]] && warn "RICE_WALLPAPER_FLAVOURS is set in this shell and overrides the saved style"
  [[ -f $STATE/palette.sh ]] || die "nothing applied yet: run 'rice.sh apply' first"
  # shellcheck disable=SC1091
  source "$STATE/palette.sh"
  info "style -> $(flavours_current)"
  wallpapers_apply "$(jq -r .THEME "$STATE/palette.json")"
}

case ${1:-} in
  install)   install ;;
  apply)     apply "${2:-}" ;;
  uninstall) uninstall ;;
  purge)     purge ;;
  status)    status ;;
  wallpapers) wallpapers "${2:-all}" ;;
  style)     shift; style "$@" ;;
  noctis-plugin) noctis_plugin ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
