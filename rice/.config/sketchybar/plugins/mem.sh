#!/usr/bin/env bash
# Used memory as a percent of physical RAM (active + wired + compressed pages).
total=$(sysctl -n hw.memsize)
page=$(vm_stat | awk '/page size of/{print $8}')
used=$(vm_stat | awk -v p="$page" '/Pages (active|wired down|occupied by compressor)/{gsub("\\.","",$NF); s+=$NF} END{print s*p}')
pct=$(( used * 100 / total ))
sketchybar --set "$NAME" label="${pct}%"
