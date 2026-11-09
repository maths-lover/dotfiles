#!/usr/bin/env bash
# theme_menu.sh — build / refresh the theme picker popup under the logo item.
# One row per alias from THEME_DARK / THEME_LIGHT in zsh/theme.zsh; the active
# one (zsh/.active-theme) is marked. Clicking a row runs `theme <alias>`, which
# re-themes the terminal and, through rice.sh apply, the whole desktop (the bar
# reloads itself as part of that).
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set logo popup.drawing=off; exit 0; fi
source "$HOME/.local/state/rice/palette.sh" 2>/dev/null
active="$(cat "$HOME/.config/zsh/.active-theme" 2>/dev/null)"
existing="$(sketchybar --query bar | jq -r '.items[]' | grep '^theme\.' || true)"
while read -r kind alias; do
  [[ -z $alias ]] && continue
  item="theme.$alias"
  if ! grep -qx "$item" <<< "$existing"; then
    sketchybar --add item "$item" popup.logo \
               --set "$item" label="$alias" label.padding_right=16 icon.padding_left=10 \
                     label.font="Maple Mono NF:Medium:12.0" \
                     click_script="$HOME/.config/sketchybar/plugins/theme_action.sh $alias"
  fi
  if [[ $alias == "$active" ]]; then
    sketchybar --set "$item" icon="󰄬" icon.color="$RICE_ACCENT_0X" label.color="$RICE_ACCENT_0X"
  else
    sketchybar --set "$item" icon="$([[ $kind == dark ]] && echo "󰖔" || echo "󰖨")" icon.color="$RICE_FG_DIM_0X" label.color="$RICE_FG_0X"
  fi
done < <(zsh -c 'source ~/.config/zsh/theme.zsh; for a in $THEME_DARK; do print "dark $a"; done; for a in $THEME_LIGHT; do print "light $a"; done' 2>/dev/null)
sketchybar --set logo label="$active"
