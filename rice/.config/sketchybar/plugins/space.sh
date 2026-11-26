#!/usr/bin/env bash
# space.sh — one Space pill. SketchyBar runs it when the pill's Space becomes or
# stops being the one on screen on its display ($SELECTED true|false); spaces.sh
# calls it the same way after a rebuild. Without $SELECTED (a forced update) keep
# the current look.
source "$HOME/.local/state/rice/palette.sh" 2>/dev/null
[[ -n ${SELECTED:-} ]] || exit 0
if [[ $SELECTED == true ]]; then
  sketchybar --set "$NAME" icon.highlight=on background.color="$RICE_SEL_BG_0X" background.border_width=1 background.border_color="$RICE_ACCENT_0X"
else
  sketchybar --set "$NAME" icon.highlight=off background.color="$RICE_BG_ALT2_0X" background.border_width=0
fi
