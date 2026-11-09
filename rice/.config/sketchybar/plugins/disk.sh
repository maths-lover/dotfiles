#!/usr/bin/env bash
# Disk: used percent of the data volume (what "/" means to the user on APFS).
# Popup (click): / and every /Volumes/* mount with used / size.
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set "$NAME" popup.drawing=off; exit 0; fi
pct=$(df -k /System/Volumes/Data 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}')
[[ -z $pct ]] && pct=$(df -k / | awk 'NR==2{gsub("%","",$5); print $5}')
args=(--set "$NAME" label="${pct}%")
i=0
while IFS=$'\t' read -r used size mnt; do
  [[ $mnt == "/System/Volumes/Data" ]] && mnt="/"
  args+=(--set "disk.v$i" drawing=on label="$(printf '%-16.16s %6s / %-6s' "$mnt" "$used" "$size")")
  i=$((i + 1)); (( i >= 5 )) && break
done < <( { df -H /System/Volumes/Data; df -H | awk '$NF ~ /^\/Volumes\//'; } | awk '$1 != "Filesystem" {mnt=$9; for(k=10;k<=NF;k++) mnt=mnt" "$k; print $3"\t"$2"\t"mnt}')
while (( i < 5 )); do args+=(--set "disk.v$i" drawing=off); i=$((i + 1)); done
sketchybar "${args[@]}"
