#!/usr/bin/env bash
# mouse.clicked on the slider passes PERCENTAGE (0-100) where the click landed.
osascript -e "set volume output volume ${PERCENTAGE:-50}"
