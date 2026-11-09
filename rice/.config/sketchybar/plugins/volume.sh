#!/usr/bin/env bash
# volume_change passes the new level in $INFO; fall back to asking macOS.
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set "$NAME" popup.drawing=off; exit 0; fi
VOL=${INFO:-$(osascript -e 'output volume of (get volume settings)')}
case $VOL in
  [6-9][0-9]|100) ICON="󰕾" ;; [3-5][0-9]) ICON="󰖀" ;; [1-9]|[1-2][0-9]) ICON="󰕿" ;; *) ICON="󰖁" ;;
esac
sketchybar --set "$NAME" icon="$ICON" label="${VOL}%" --set volume.slider slider.percentage="$VOL"
