-- float.lua — decide which windows must never be managed (moved/resized).
--
-- A window is "floating" (skip it) when it:
--   * belongs to a float-listed app (e.g. Neovide), or
--   * is not a standard window — dialogs, sheets, popovers, alerts, and the
--     system password/permission prompts (subrole ~= AXStandardWindow).

local config = require("config")

local M = {}

function M.isFloat(win)
	if not win then
		return true
	end

	local app = win:application()
	if app and config.floatApps[app:name()] then
		return true
	end

	-- Non-standard windows: dialogs, sheets, popovers, system prompts.
	if win.isStandard and not win:isStandard() then
		return true
	end

	local subrole = win.subrole and win:subrole() or nil
	if subrole and subrole ~= "AXStandardWindow" then
		return true
	end

	return false
end

return M
