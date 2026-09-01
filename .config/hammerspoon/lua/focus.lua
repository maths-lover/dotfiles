-- focus.lua — GLOBAL directional window focus (no window mode needed).
--
-- Cmd+Ctrl+h/j/k/l focus the window to the left/down/up/right, across displays.
-- These are global (not modal) so one chord moves focus without entering window
-- mode. Conflict-free: macOS has no default Cmd+Ctrl+hjkl, and terminal/nvim
-- never see Cmd, so nvim's Ctrl+hjkl splits and Option word-motions are untouched.

local config = require("config")
local display = require("display")

local M = {}

local mods = config.focusMods
hs.hotkey.bind(mods, "h", function()
	display.focusDir("West")
end)
hs.hotkey.bind(mods, "j", function()
	display.focusDir("South")
end)
hs.hotkey.bind(mods, "k", function()
	display.focusDir("North")
end)
hs.hotkey.bind(mods, "l", function()
	display.focusDir("East")
end)

return M
