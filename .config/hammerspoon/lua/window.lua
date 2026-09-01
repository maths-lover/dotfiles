-- window.lua — frame operations on the focused window (pure geometry).
--
-- Every op runs through act(): if there is no focused window, or the focused
-- window is floating / non-standard, it is a no-op with a brief alert. Frames
-- use screen:frame() (the usable area, menubar/dock excluded), and are computed
-- relative to the window's CURRENT screen, so snapping is per-display.

local config = require("config")
local float = require("float")

local M = {}

-- Focused window if it is safe to manage, else nil (+ alert).
local function focused()
	local win = hs.window.focusedWindow()
	if not win then
		hs.alert.show("no window", config.alertDuration)
		return nil
	end
	if float.isFloat(win) then
		hs.alert.show("skipped", config.alertDuration)
		return nil
	end
	return win
end

-- Run fn(win) on the focused manageable window.
local function act(fn)
	local win = focused()
	if win then
		fn(win)
	end
end

-- Place a window at a fraction of its screen's usable frame.
local function setFrac(win, x, y, w, h)
	local f = win:screen():frame()
	win:setFrame({
		x = f.x + f.w * x,
		y = f.y + f.h * y,
		w = f.w * w,
		h = f.h * h,
	})
end

-- Halves
function M.left()
	act(function(w)
		setFrac(w, 0, 0, 0.5, 1)
	end)
end
function M.right()
	act(function(w)
		setFrac(w, 0.5, 0, 0.5, 1)
	end)
end
function M.top()
	act(function(w)
		setFrac(w, 0, 0, 1, 0.5)
	end)
end
function M.bottom()
	act(function(w)
		setFrac(w, 0, 0.5, 1, 0.5)
	end)
end

-- Thirds (direct)
function M.thirdLeft()
	act(function(w)
		setFrac(w, 0, 0, 1 / 3, 1)
	end)
end
function M.thirdCenter()
	act(function(w)
		setFrac(w, 1 / 3, 0, 1 / 3, 1)
	end)
end
function M.thirdRight()
	act(function(w)
		setFrac(w, 2 / 3, 0, 1 / 3, 1)
	end)
end

-- Two-thirds
function M.twoThirdLeft()
	act(function(w)
		setFrac(w, 0, 0, 2 / 3, 1)
	end)
end
function M.twoThirdRight()
	act(function(w)
		setFrac(w, 1 / 3, 0, 2 / 3, 1)
	end)
end

-- Quarters
function M.topLeft()
	act(function(w)
		setFrac(w, 0, 0, 0.5, 0.5)
	end)
end
function M.topRight()
	act(function(w)
		setFrac(w, 0.5, 0, 0.5, 0.5)
	end)
end
function M.bottomLeft()
	act(function(w)
		setFrac(w, 0, 0.5, 0.5, 0.5)
	end)
end
function M.bottomRight()
	act(function(w)
		setFrac(w, 0.5, 0.5, 0.5, 0.5)
	end)
end

-- Maximize (fill usable frame) / center (keep size)
function M.maximize()
	act(function(w)
		w:setFrame(w:screen():frame())
	end)
end
function M.center()
	act(function(w)
		w:centerOnScreen(nil, true)
	end)
end

-- Thirds cycle across the L -> C -> R columns.
local COLS = { { x = 0, w = 1 / 3 }, { x = 1 / 3, w = 1 / 3 }, { x = 2 / 3, w = 1 / 3 } }

local function nearestCol(win)
	local f = win:screen():frame()
	local rel = (win:frame().x - f.x) / f.w
	local best, bestd = 1, math.huge
	for i, c in ipairs(COLS) do
		local d = math.abs(rel - c.x)
		if d < bestd then
			best, bestd = i, d
		end
	end
	return best
end

local function cycle(dir)
	act(function(win)
		local i = ((nearestCol(win) - 1 + dir) % #COLS) + 1
		setFrac(win, COLS[i].x, 0, COLS[i].w, 1)
	end)
end
function M.cycleThirdLeft()
	cycle(-1)
end
function M.cycleThirdRight()
	cycle(1)
end

-- Grow / shrink uniformly about the window centre, clamped to the screen.
local function scale(win, step)
	local f = win:screen():frame()
	local wf = win:frame()
	local nw = math.max(200, math.min(wf.w + f.w * step, f.w))
	local nh = math.max(150, math.min(wf.h + f.h * step, f.h))
	local nx = wf.x - (nw - wf.w) / 2
	local ny = wf.y - (nh - wf.h) / 2
	nx = math.max(f.x, math.min(nx, f.x + f.w - nw))
	ny = math.max(f.y, math.min(ny, f.y + f.h - nh))
	win:setFrame({ x = nx, y = ny, w = nw, h = nh })
end
function M.grow()
	act(function(w)
		scale(w, config.resizeStep)
	end)
end
function M.shrink()
	act(function(w)
		scale(w, -config.resizeStep)
	end)
end

return M
