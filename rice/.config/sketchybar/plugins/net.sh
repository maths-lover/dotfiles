#!/usr/bin/env bash
# Network throughput of the default interface from `netstat -ib` byte deltas.
# Last sample lives in ~/.local/state/rice/net.prev ("epoch rx tx iface").
# Graph = download on a log scale (1.0 = 100 MB/s). No Wi-Fi/SSID info on purpose.
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set "$NAME" popup.drawing=off; exit 0; fi
PREV="$HOME/.local/state/rice/net.prev"
ifc=$(route -n get default 2>/dev/null | awk '/interface/{print $2}')
if [[ -z $ifc ]]; then
  sketchybar --push "$NAME" 0 --set "$NAME" label="offline" --set net.if label="no connection" --set net.ip label="-"
  exit 0
fi
read -r rx tx < <(netstat -ib -I "$ifc" | awk '$3 ~ /^<Link/ {print $(NF-4), $(NF-1); exit}')
now=$(date +%s)
read -r pt prx ptx pif < "$PREV" 2>/dev/null
echo "$now $rx $tx $ifc" > "$PREV"
dr=0; ut=0
if [[ $pif == "$ifc" && -n $pt ]] && (( now > pt && rx >= prx && tx >= ptx )); then
  dt=$((now - pt)); dr=$(( (rx - prx) / dt )); ut=$(( (tx - ptx) / dt ))
fi
h() { awk -v b="$1" 'BEGIN{ if(b>=1048576) printf "%.1fM", b/1048576; else if(b>=1024) printf "%dK", b/1024; else printf "%dB", b }'; }
v=$(awk -v r="$dr" 'BEGIN{ v=log(1+r)/log(10)/8; if(v>1)v=1; printf "%.3f", v }')
sketchybar --push "$NAME" "$v" --set "$NAME" label="↓ $(h $dr) ↑ $(h $ut)" \
           --set net.if label="interface  $ifc" --set net.ip label="ip  $(ipconfig getifaddr "$ifc" 2>/dev/null || echo -)"
