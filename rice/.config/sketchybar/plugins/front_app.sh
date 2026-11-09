#!/usr/bin/env bash
# front_app_switched passes the app name in $INFO. The icon map ships with
# sketchybar-app-font; rice.sh downloads it to the state dir. Missing map = no icon.
# mouse.exited.global closes the Hide/Quit menu when the pointer leaves the bar.
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set "$NAME" popup.drawing=off; exit 0; fi
# `sketchybar --update` (SENDER=forced) calls us with no app name: keep what we have.
[[ -z $INFO ]] && exit 0
ICON_MAP="$HOME/.local/state/rice/bin/icon_map.sh"
icon=""
[[ -x "$ICON_MAP" ]] && icon="$("$ICON_MAP" "$INFO" 2>/dev/null)"
sketchybar --set "$NAME" label="$INFO" icon="${icon:-:default:}" popup.drawing=off
