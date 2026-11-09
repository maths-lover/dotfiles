#!/usr/bin/env bash
# CPU: sum of per-process %cpu over the core count; push to the graph (0-1), label %.
# Popup (click): top 5 processes, load average, uptime.
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set "$NAME" popup.drawing=off; exit 0; fi
cores=$(sysctl -n hw.ncpu)
pct=$(ps -A -o %cpu= | awk -v c="$cores" '{s+=$1} END{printf "%d", s/c}')
(( pct > 100 )) && pct=100
args=(--push "$NAME" "$(awk -v p="$pct" 'BEGIN{printf "%.3f", p/100}')" --set "$NAME" label="${pct}%")
i=0
while read -r cpu comm; do
  args+=(--set "cpu.p$i" label="$(awk -v r="$cpu" -v c="$comm" 'BEGIN{printf "%-22.22s %6.1f %%", c, r}')")
  i=$((i + 1))
done < <(ps -Aceo pcpu,comm -r | awk 'NR>1 && NR<=6')
load="$(sysctl -n vm.loadavg | tr -d '{}' | awk '{print $1, $2, $3}')"
up="$(uptime | sed -E 's/^.* up +//; s/, +[0-9]+ users?.*//')"
args+=(--set cpu.load label="load  $load" --set cpu.up label="up  $up")
sketchybar "${args[@]}"
