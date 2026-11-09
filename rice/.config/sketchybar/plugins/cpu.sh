#!/usr/bin/env bash
# CPU: sum of per-process %cpu over the core count; push to the graph (0-1), label %.
cores=$(sysctl -n hw.ncpu)
pct=$(ps -A -o %cpu= | awk -v c="$cores" '{s+=$1} END{printf "%d", s/c}')
(( pct > 100 )) && pct=100
sketchybar --push "$NAME" "$(awk -v p="$pct" 'BEGIN{printf "%.3f", p/100}')" --set "$NAME" label="${pct}%"
