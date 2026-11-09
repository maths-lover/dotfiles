#!/usr/bin/env bash
# mode_change (raised by skhdrc) passes MODE=window|default. Show the badge only in window mode.
if [[ $MODE == "window" ]]; then sketchybar --set "$NAME" drawing=on; else sketchybar --set "$NAME" drawing=off; fi
