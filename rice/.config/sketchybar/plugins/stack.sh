#!/usr/bin/env bash
# stack.sh — a cue that the focused window has others stacked behind it.
# yabai stacks (Ghostty tabs, the portrait display's fourth window, see
# ~/.config/yabai/tall-display) share one frame, so on screen nothing shows
# a window is hiding behind the one you see. This item appears only then:
# "2/3" = position in the stack, then the names of the hidden windows.
# Click: focus the next window in the stack (wraps).
# Runs on stack_change (raised by yabai signals and tall-display),
# front_app_switched and space_change.
w="$(yabai -m query --windows --window 2>/dev/null)" || { sketchybar --set "$NAME" drawing=off; exit 0; }
idx="$(jq -r '.["stack-index"] // 0' <<< "$w")"
if (( idx == 0 )); then sketchybar --set "$NAME" drawing=off; exit 0; fi
space="$(jq -r .space <<< "$w")"; frame="$(jq -c .frame <<< "$w")"
# Stack members: tiled windows on the Space with the same frame.
members="$(yabai -m query --windows --space "$space" 2>/dev/null | jq -r --argjson f "$frame" --argjson me "$idx" '
  [.[] | select(.frame == $f and .["stack-index"] > 0)] | sort_by(.["stack-index"])
  | "\(length)\t" + ([.[] | select(.["stack-index"] != $me) | .app] | join(", "))')"
n="${members%%$'\t'*}"; others="${members#*$'\t'}"
if (( n < 2 )); then sketchybar --set "$NAME" drawing=off; exit 0; fi
sketchybar --set "$NAME" drawing=on label="$idx/$n  $others"
