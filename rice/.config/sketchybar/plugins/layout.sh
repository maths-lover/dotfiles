#!/usr/bin/env bash
# layout.sh — per-display bar layout. A portrait display (taller than wide: the 1080x1920
# panel) is too narrow for the whole status cluster, so while one is connected the heavy
# items only draw on the wide displays; the portrait bar keeps the theme logo, its Space
# pills, the front app, volume, battery and the clock. With no portrait display every item
# is on every display. Runs at startup (sketchybarrc) and on display_change.
WIDE_ONLY="music cpu mem net disk"
displays=$(sketchybar --query displays)
all=$(jq -r '[.[] | ."arrangement-id"] | join(",")' <<< "$displays")
wide=$(jq -r '[.[] | select(.frame.w > .frame.h) | ."arrangement-id"] | join(",")' <<< "$displays")
[[ -n $wide ]] || wide=$all   # only portrait displays: show everything rather than nothing
args=()
for item in $WIDE_ONLY; do args+=(--set "$item" display="$wide"); done
sketchybar "${args[@]}"
