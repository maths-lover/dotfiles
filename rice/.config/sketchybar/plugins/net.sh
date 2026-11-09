#!/usr/bin/env bash
# net.sh — network status + the details popup.
# Bar: Wi-Fi icon by signal strength (or LAN / offline) and the network name.
# macOS only reveals the SSID to processes with Location Services permission, so
# without that it reads "Wi-Fi" (System Settings > Privacy & Security > Location
# Services > sketchybar fixes it). Popup (click): name, IP/router, signal, channel,
# rate, security, plus "Turn Wi-Fi off/on" and "Open Wi-Fi settings".
# Runs every 60s and on wifi_change / system_woke; system_profiler is the only
# source for signal data and takes ~4s, so the popup shows cached values.
if [[ $SENDER == "mouse.exited.global" ]]; then sketchybar --set "$NAME" popup.drawing=off; exit 0; fi
source "$HOME/.local/state/rice/palette.sh" 2>/dev/null
dim="$RICE_FG_DIM_0X"

set_popup() {  # set_popup <name> <ip> <signal> <security> <toggle label> <toggle shown>
  sketchybar --set net.name label="$1" --set net.ip label="$2" --set net.signal label="$3" --set net.security label="$4" \
             --set net.toggle label="$5" drawing="$6"
}

iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
wifi_if="$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $2}')"
power="$(networksetup -getairportpower "$wifi_if" 2>/dev/null | awk '{print $NF}')"

if [[ -z $iface ]]; then
  sketchybar --set "$NAME" icon="󰤭" label="offline" label.color="$dim"
  set_popup "Not connected" "" "" "" "Turn Wi-Fi $([[ $power == On ]] && echo off || echo on)" on
  exit 0
fi
ip="$(ipconfig getifaddr "$iface" 2>/dev/null)"
router="$(ipconfig getsummary "$iface" 2>/dev/null | awk -F': ' '/ Router : /{print $2; exit}')"
if [[ $iface != "$wifi_if" ]]; then
  sketchybar --set "$NAME" icon="󰈀" label="LAN" label.color="$RICE_FG_0X"
  set_popup "Ethernet ($iface)" "IP ${ip:-?}  ·  router ${router:-?}" "" "" "Turn Wi-Fi $([[ $power == On ]] && echo off || echo on)" on
  exit 0
fi
ssid="$(ipconfig getsummary "$iface" 2>/dev/null | awk -F': ' '/ SSID : /{print $2; exit}')"
[[ -z $ssid || $ssid == "<redacted>" ]] && ssid=""
info="$(system_profiler SPAirPortDataType -json 2>/dev/null | jq -r --arg i "$iface" '
  .SPAirPortDataType[0].spairport_airport_interfaces[] | select(._name == $i) | .spairport_current_network_information
  | [(.spairport_signal_noise // ""), (.spairport_network_channel // ""), ((.spairport_network_rate // "") | tostring),
     (.spairport_network_phymode // ""), ((.spairport_security_mode // "") | sub("spairport_security_mode_"; "") | gsub("_"; " "))] | @tsv' 2>/dev/null)"
IFS=$'\t' read -r sn channel rate phy sec <<< "$info"
rssi="${sn%% *}"; rssi="${rssi:-0}"
case ${rssi#-} in
  0)                       icon="󰤯" ;;   # unknown
  [1-5][0-9])              icon="󰤨" ;;   # better than -60 dBm
  6[0-9])                  icon="󰤥" ;;
  7[0-9])                  icon="󰤢" ;;
  *)                       icon="󰤟" ;;
esac
sketchybar --set "$NAME" icon="$icon" label="${ssid:-Wi-Fi}" label.color="$RICE_FG_0X"
set_popup "${ssid:-Wi-Fi  (name hidden by macOS)}" \
          "IP ${ip:-?}   router ${router:-?}" \
          "${sn:-signal ?}   ch ${channel:-?}" \
          "${rate:-?} Mb/s ${phy}   ${sec:-}" "Turn Wi-Fi off" on
