-- modal.lua — the sticky "window mode" modal and its keymap.
--
-- Enter with the entry chord (default Cmd+Ctrl+Space). While active, bare keys
-- act (no modifiers), the mode PERSISTS so ops can be chained, and Esc/q exits.
-- Modal keys only fire while the modal owns the keyboard, so they never clash
-- with nvim's Ctrl+hjkl or the terminal's Option/Meta.
-- Focus is GLOBAL (Cmd+Ctrl+h/j/k/l, see lua/focus.lua), not bound here.

local config = require("config")
local window = require("window")
local display = require("display")

local M = {}

local mode = hs.hotkey.modal.new(config.entryChord.mods, config.entryChord.key)

function mode:entered()
	hs.alert.show("window mode", config.modeAlertDuration)
end
function mode:exited()
	hs.alert.show("window mode off", config.modeAlertDuration)
end

-- bind a bare key (no modifiers) to fn while the modal is active.
local function bind(key, fn)
	mode:bind({}, key, fn)
end

-- Halves
bind("h", window.left)
bind("j", window.bottom)
bind("k", window.top)
bind("l", window.right)

-- Thirds (direct) + two-thirds
bind("1", window.thirdLeft)
bind("2", window.thirdCenter)
bind("3", window.thirdRight)
bind("4", window.twoThirdLeft)
bind("6", window.twoThirdRight)

-- Thirds cycle
bind("[", window.cycleThirdLeft)
bind("]", window.cycleThirdRight)

-- Quarters
bind("y", window.topLeft)
bind("u", window.topRight)
bind("b", window.bottomLeft)
bind("n", window.bottomRight)

-- Maximize / center
bind("m", window.maximize)
bind("c", window.center)

-- Grow / shrink
bind("=", window.grow)
bind("-", window.shrink)

-- Move window to next / previous display
mode:bind({}, "tab", function()
	display.moveToDisplay(1)
end)
mode:bind({ "shift" }, "tab", function()
	display.moveToDisplay(-1)
end)

-- Reload config from inside the modal
bind("r", function()
	hs.reload()
end)

-- Exit
mode:bind({}, "escape", function()
	mode:exit()
end)
bind("q", function()
	mode:exit()
end)

M.mode = mode
return M
