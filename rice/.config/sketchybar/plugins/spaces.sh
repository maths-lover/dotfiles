#!/usr/bin/env bash
# spaces.sh — (re)build the Space pills: one native SketchyBar `space` item per
# Mission Control desktop, icon = Space number, label = one glyph per app on that
# Space (sketchybar-app-font via icon_map.sh). SketchyBar draws each pill on the
# display its Space is on and runs plugins/space.sh when it becomes (or stops being)
# the selected one. The desktop list comes from ricelib (the Dock's preferences +
# CoreGraphics), the same source the wallpapers use; the apps per Space come from
# SketchyBar's space_windows_change events ({"space": N, "apps": {"App": count}}),
# so a pill's label fills in on the first window change on that Space.
# Click: Mission Control. No window manager runs here, so there is nothing a
# script could switch Spaces with (Mission Control's own Ctrl+N shortcuts are off
# because Reef uses those keys).
# Runs at bar start and on space_change / display_change (rebuild the list) and
# on space_windows_change (relabel one pill).
ICON_MAP="$HOME/.local/state/rice/bin/icon_map.sh"
LIB="$HOME/.config/rice/ricelib.py"
PLUGIN_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}/plugins"
source "$HOME/.local/state/rice/palette.sh" 2>/dev/null

strip_for() {  # strip_for <app>... -> one glyph per app
  local app g out=""
  for app in "$@"; do
    g=""; [[ -x $ICON_MAP ]] && g="$("$ICON_MAP" "$app" 2>/dev/null)"
    out+="${g:-:default:}"
  done
  printf '%s' "$out"
}

if [[ $SENDER == space_windows_change ]]; then
  sid="$(jq -r '.space // empty' <<< "$INFO")"; [[ -n $sid ]] || exit 0
  mapfile -t apps < <(jq -r '.apps | keys[]' <<< "$INFO")
  strip="$(strip_for "${apps[@]}")"
  sketchybar --set "space.$sid" label="$strip" label.drawing="$([[ -n $strip ]] && echo on || echo off)" 2>/dev/null
  exit 0
fi

# One rebuild at a time: at bar start the init call and the first events overlap and
# would add/remove the same items twice (harmless, but noisy in the log).
LOCK="$HOME/.local/state/rice/spaces.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  # Stale lock (a previous run died, or a reboot cut one short)? Older than
  # 10 s = take it over. Compare mtimes with stat: `find -mmin` only takes
  # whole minutes (and bfs, if it stands in for find, rejects fractions).
  if (( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) > 10 )); then
    rmdir "$LOCK" 2>/dev/null; mkdir "$LOCK" 2>/dev/null || exit 0
  else
    exit 0
  fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

list="$(python3 -IB "$LIB" spaces 2>/dev/null)"
[[ -n $list ]] || exit 0        # displays asleep: keep what we have
wanted="$(awk '{print $1}' <<< "$list")"
existing="$(sketchybar --query bar | jq -r '.items[]' | grep '^space\.' | sed 's/^space\.//' | sort -n)"

# Remove pills for Spaces that no longer exist, add pills for new ones.
for s in $(comm -23 <(echo "$existing") <(echo "$wanted")); do sketchybar --remove "space.$s"; done
for s in $(comm -13 <(echo "$existing") <(echo "$wanted")); do
  sketchybar --add space "space.$s" left \
             --set "space.$s" space="$s" icon="$s" icon.padding_left=9 icon.padding_right=4 \
                   icon.highlight_color="$RICE_ACCENT_0X" \
                   label.font="sketchybar-app-font:Regular:13.0" label.padding_right=9 label.drawing=off \
                   background.drawing=on background.color="$RICE_BG_ALT2_0X" \
                   script="$PLUGIN_DIR/space.sh" \
                   click_script="open -b com.apple.exposelauncher"
done
# Keep them ordered by Space number, before front_app.
sketchybar --move front_app after "space.$(echo "$wanted" | tail -1)" 2>/dev/null
prev=""; for s in $wanted; do [[ -n $prev ]] && sketchybar --move "space.$s" after "space.$prev"; prev=$s; done
# Highlight the Space on screen on each display right away (SketchyBar only runs
# space.sh when that changes).
while read -r s _ _ _ _ _ cur; do
  SELECTED="$([[ $cur == 1 ]] && echo true || echo false)" NAME="space.$s" "$PLUGIN_DIR/space.sh"
done <<< "$list"
