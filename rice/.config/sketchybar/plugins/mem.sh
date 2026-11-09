#!/usr/bin/env bash
# Memory: used percent of RAM (active + wired + compressed pages) -> graph + label.
# Popup (click): top 5 processes by resident memory.
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set "$NAME" popup.drawing=off; exit 0; fi
total=$(sysctl -n hw.memsize)
page=$(vm_stat | awk '/page size of/{print $8}')
used=$(vm_stat | awk -v p="$page" '/Pages (active|wired down|occupied by compressor)/{gsub("\\.","",$NF); s+=$NF} END{print s*p}')
pct=$(( used * 100 / total ))
args=(--push "$NAME" "$(awk -v p="$pct" 'BEGIN{printf "%.3f", p/100}')" --set "$NAME" label="${pct}%")
i=0
while read -r rss comm; do
  args+=(--set "mem.p$i" label="$(awk -v r="$rss" -v c="$comm" 'BEGIN{printf "%-22.22s %6.0f MB", c, r/1024}')")
  i=$((i + 1))
done < <(ps -Aceo rss,comm -r | awk 'NR>1 && NR<=6')
sketchybar "${args[@]}"
