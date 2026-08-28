-- config.lua — tunables. Edit here, then save (auto-reloads) or Cmd+Ctrl+R.

local M = {}

-- Modal entry chord for "window mode" (sticky until Esc/q).
-- NOTE: Cmd+Ctrl+Space is macOS's default Character Viewer shortcut; binding it
-- here shadows that. Change these to rebind (see docs 13 + 17).
M.entryChord = { mods = { "cmd", "ctrl" }, key = "space" }

-- Global manual-reload hotkey (works outside the modal too).
M.reloadHotkey = { mods = { "cmd", "ctrl" }, key = "r" }

-- Grow/shrink step as a fraction of the screen, per keypress.
M.resizeStep = 0.05

-- Apps whose windows are never moved/resized (treated as floating).
-- Matched by application name. Neovide (incl. the scratchpad) stays put.
M.floatApps = {
  ["Neovide"] = true,
}

-- Alert timings (seconds).
M.alertDuration     = 0.6   -- "skipped" / "no window" / "one display"
M.modeAlertDuration = 0.4   -- entering/leaving window mode

-- Shown on load and on every reload.
M.startupText = "Hammerspoon loaded"

return M
