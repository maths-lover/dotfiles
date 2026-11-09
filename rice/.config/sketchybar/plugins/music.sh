#!/usr/bin/env bash
# music.sh — now playing from Noctis's Local API (Settings > Account & Devices >
# Local API). Noctis publishes port + token in local-api.json; the API only
# answers on 127.0.0.1. Hidden when Noctis or its API is not running.
# Bar: play/pause icon + "Title · Artist". Click: play/pause. Popup (hover): album,
# position, prev / next buttons (plugins/music_action.sh).
# Reference: https://github.com/heartached/Noctis/blob/main/docs/LOCAL-API.md
CFG="$HOME/Library/Application Support/Noctis/local-api.json"
[[ -f $CFG ]] || CFG="$HOME/.config/Noctis/local-api.json"
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set "$NAME" popup.drawing=off; exit 0; fi
hide() { sketchybar --set "$NAME" drawing=off popup.drawing=off; exit 0; }
[[ -f $CFG ]] || hide
read -r port token < <(jq -r 'select(.running == true) | "\(.port) \(.token)"' "$CFG" 2>/dev/null)
[[ -n $port && $port != null ]] || hide
np="$(curl -s --max-time 1 -H "Authorization: Bearer $token" "http://127.0.0.1:$port/api/v1/now-playing")" || hide
[[ -n $np ]] || hide
IFS=$'\t' read -r state title artist album pos dur < <(jq -r '[.state, (.title // ""), ((.artists // []) | join(", ")), (.album // ""), (.positionMs // 0), (.durationMs // 0)] | @tsv' <<< "$np" 2>/dev/null)
[[ -z $title || $state == stopped ]] && hide
icon="󰐊"; [[ $state == playing ]] && icon="󰏤"
fmt() { printf '%d:%02d' $(( $1 / 60000 )) $(( $1 / 1000 % 60 )); }
sketchybar --set "$NAME" drawing=on icon="$icon" label="$title · $artist" \
           --set music.album label="${album:-—}" \
           --set music.pos label="$(fmt "$pos") / $(fmt "$dur")"
