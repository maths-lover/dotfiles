#!/usr/bin/env bash
# theme_action.sh <alias> — switch the theme from the bar. `theme` is a zsh
# function (zsh/theme.zsh); it persists the choice, recolours open Ghostty
# windows and kicks off rice.sh apply in the background, which reloads the bar.
sketchybar --set logo popup.drawing=off
zsh -c "source ~/.config/zsh/theme.zsh; theme ${1:?alias}" >/dev/null 2>&1 &
