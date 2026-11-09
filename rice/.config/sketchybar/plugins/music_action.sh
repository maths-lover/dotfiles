#!/usr/bin/env bash
# music_action.sh toggle|next|previous — playback control through Noctis's Local API.
CFG="$HOME/Library/Application Support/Noctis/local-api.json"
[[ -f $CFG ]] || CFG="$HOME/.config/Noctis/local-api.json"
read -r port token < <(jq -r 'select(.running == true) | "\(.port) \(.token)"' "$CFG" 2>/dev/null)
[[ -n $port && $port != null ]] || exit 0
curl -s --max-time 1 -X POST -H "Authorization: Bearer $token" "http://127.0.0.1:$port/api/v1/playback/${1:-toggle}" >/dev/null
sleep 0.3; sketchybar --update
