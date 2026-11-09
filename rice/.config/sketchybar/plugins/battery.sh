#!/usr/bin/env bash
# Hide on desktops with no battery; otherwise icon by level, label = percent.
PERCENT=$(pmset -g batt | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
if [[ -z "$PERCENT" ]]; then sketchybar --set "$NAME" drawing=off; exit 0; fi
CHARGING=$(pmset -g batt | grep -c 'AC Power')
case $PERCENT in
  9[0-9]|100) ICON="󰁹" ;; [6-8][0-9]) ICON="󰂀" ;; [3-5][0-9]) ICON="󰁾" ;; [1-2][0-9]) ICON="󰁻" ;; *) ICON="󰂎" ;;
esac
(( CHARGING )) && ICON="󰂄"
sketchybar --set "$NAME" drawing=on icon="$ICON" label="${PERCENT}%"
