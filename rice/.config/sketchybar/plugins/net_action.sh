#!/usr/bin/env bash
# net_action.sh toggle|settings — buttons in the network popup.
sketchybar --set net popup.drawing=off
wifi_if="$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $2}')"
case $1 in
  toggle)
    if [[ "$(networksetup -getairportpower "$wifi_if" | awk '{print $NF}')" == On ]]; then networksetup -setairportpower "$wifi_if" off
    else networksetup -setairportpower "$wifi_if" on; fi
    sleep 2; sketchybar --update ;;
  settings) open "x-apple.systempreferences:com.apple.wifi-settings-extension" ;;
esac
