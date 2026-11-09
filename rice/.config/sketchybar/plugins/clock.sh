#!/usr/bin/env bash
# Clock label, and the calendar popup: one popup item per line of `cal`.
# Today's number is wrapped in brackets (BSD sed: no \b, so match on spaces).
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set "$NAME" popup.drawing=off; exit 0; fi
sketchybar --set "$NAME" label="$(date '+%a %d %b  %H:%M')"
today="$(date +%e | tr -d ' ')"
i=0
while IFS= read -r line; do
  sketchybar --set "clock.cal.$i" label="$line" drawing=on
  i=$((i + 1))
done < <(cal | sed -E "s/ *\$//; 3,\$s/ ${today} /[${today}]/; 3,\$s/^${today} /[${today}]/; 3,\$s/ ${today}\$/[${today}]/" | head -8)
while (( i < 8 )); do sketchybar --set "clock.cal.$i" drawing=off; i=$((i + 1)); done
