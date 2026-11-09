#!/usr/bin/env bash
# Called for every space item on space change. SELECTED=true for the active space.
# Highlight = accent icon on a raised pill; others plain.
sketchybar --set "$NAME" icon.highlight="$SELECTED" background.drawing="$SELECTED"
