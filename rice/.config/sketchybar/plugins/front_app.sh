#!/usr/bin/env bash
# front_app_switched passes the app name in $INFO. The icon map ships with
# sketchybar-app-font; rice.sh downloads it to the state dir. Missing map = no icon.
ICON_MAP="$HOME/.local/state/rice/bin/icon_map.sh"
icon=""
[[ -x "$ICON_MAP" ]] && icon="$("$ICON_MAP" "$INFO" 2>/dev/null)"
sketchybar --set "$NAME" label="$INFO" icon="${icon:-:default:}"
