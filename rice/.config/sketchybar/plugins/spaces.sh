#!/usr/bin/env bash
# spaces.sh — (re)build the Space pills from yabai's view of the world.
# One item per Mission Control Space, placed on the display it belongs to
# (display=N), icon = Space number, label = one glyph per app on that Space
# (sketchybar-app-font via icon_map.sh). The Space visible on each display is
# highlighted. Click: switch to that Space (focus-space, see ~/.config/yabai).
# Runs at bar start and on space_change / space_windows_change / display_change.
# One run at a time: at bar start the init call and the first events overlap and
# would add/remove the same items twice (harmless, but noisy in the log).
LOCK="$HOME/.local/state/rice/spaces.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  # stale lock (a previous run died)? older than 10 s = take it over
  if [[ -n $(find "$LOCK" -maxdepth 0 -mmin +0.17 2>/dev/null) ]]; then rmdir "$LOCK" 2>/dev/null; mkdir "$LOCK" 2>/dev/null || exit 0; else exit 0; fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
ICON_MAP="$HOME/.local/state/rice/bin/icon_map.sh"
FOCUS="$HOME/.config/yabai/focus-space"
source "$HOME/.local/state/rice/palette.sh" 2>/dev/null

spaces="$(yabai -m query --spaces 2>/dev/null)" || exit 0
jq -e 'length > 0' <<< "$spaces" >/dev/null 2>&1 || exit 0
windows="$(yabai -m query --windows 2>/dev/null)"

existing="$(sketchybar --query bar | jq -r '.items[]' | grep '^space\.' | sed 's/^space\.//' | sort -n)"
wanted="$(jq -r '.[].index' <<< "$spaces" | sort -n)"

# Remove pills for Spaces that no longer exist, add pills for new ones.
for s in $(comm -23 <(echo "$existing") <(echo "$wanted")); do sketchybar --remove "space.$s"; done
for s in $(comm -13 <(echo "$existing") <(echo "$wanted")); do
  sketchybar --add item "space.$s" left \
             --set "space.$s" icon="$s" icon.padding_left=9 icon.padding_right=4 \
                   icon.highlight_color="$RICE_ACCENT_0X" \
                   label.font="sketchybar-app-font:Regular:13.0" label.padding_right=9 \
                   background.drawing=on background.color="$RICE_BG_ALT2_0X" \
                   click_script="$FOCUS $s"
done
# Keep them ordered by Space index, before front_app.
sketchybar --move front_app after "space.$(echo "$wanted" | tail -1)" 2>/dev/null
prev=""; for s in $wanted; do [[ -n $prev ]] && sketchybar --move "space.$s" after "space.$prev"; prev=$s; done

# Fill each pill.
while IFS=$'\t' read -r idx display visible; do
  apps="$(jq -r --argjson i "$idx" '[.[] | select(.space == $i and ."is-minimized" == false and .role == "AXWindow") | .app] | unique | .[]' <<< "$windows")"
  strip=""
  while IFS= read -r app; do
    [[ -z $app ]] && continue
    g=""; [[ -x $ICON_MAP ]] && g="$("$ICON_MAP" "$app" 2>/dev/null)"
    strip+="${g:-:default:}"
  done <<< "$apps"
  if [[ $visible == true ]]; then
    sketchybar --set "space.$idx" display="$display" label="$strip" label.drawing="$([[ -n $strip ]] && echo on || echo off)" \
               icon.highlight=on background.color="$RICE_SEL_BG_0X" background.border_width=1 background.border_color="$RICE_ACCENT_0X"
  else
    sketchybar --set "space.$idx" display="$display" label="$strip" label.drawing="$([[ -n $strip ]] && echo on || echo off)" \
               icon.highlight=off background.color="$RICE_BG_ALT2_0X" background.border_width=0
  fi
done < <(jq -r '.[] | "\(.index)\t\(.display)\t\(."is-visible")"' <<< "$spaces")
