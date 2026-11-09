#!/usr/bin/env bash
# app_action.sh hide|quit|force — act on the app shown in the front_app item.
# quit asks the app to quit (unsaved-changes dialogs still appear); force kills it.
# The pid comes from yabai so nothing here needs Automation permissions except
# `hide`, which goes through System Events (macOS asks once).
action="${1:?hide|quit|force}"
sketchybar --set front_app popup.drawing=off
app="$(sketchybar --query front_app | jq -r '.label.value')"
pid="$(yabai -m query --windows --window 2>/dev/null | jq -r '.pid // empty')"
[[ -z $pid ]] && pid="$(pgrep -x "$app" | head -1)"
case $action in
  hide)  osascript -e "tell application \"System Events\" to set visible of (first process whose name is \"$app\") to false" ;;
  quit)  osascript -e "tell application \"$app\" to quit" 2>/dev/null || { [[ -n $pid ]] && kill -TERM "$pid"; } ;;
  force) [[ -n $pid ]] && kill -KILL "$pid" ;;
esac
