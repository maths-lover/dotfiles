-- display.lua — multi-display: move a window between screens, focus across
-- screens, and stay sane when displays are (un)plugged.
--
-- Screens are queried live (hs.screen.allScreens), so plugging/unplugging is
-- handled naturally; the screen watcher is kept as a hook and to surface state.
-- With a single display, move-to-display is a no-op + alert (never an error).

local config = require("config")
local float  = require("float")

local M = {}

-- Focused window if safe to MOVE, else nil (+ alert). Focus ops don't use this
-- (focusing a dialog is harmless), but moving one across displays is guarded.
local function movable()
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

-- Move focused window to the next (dir=1) / previous (dir=-1) display, wrapping.
function M.moveToDisplay(dir)
  local win = movable()
  if not win then return end

  local screens = hs.screen.allScreens()
  if #screens < 2 then
    hs.alert.show("one display", config.alertDuration)
    return
  end

  local cur, idx = win:screen(), 1
  for i, s in ipairs(screens) do
    if s:id() == cur:id() then idx = i break end
  end
  local target = screens[((idx - 1 + dir) % #screens) + 1]
  win:moveToScreen(target, false, true)   -- keep relative geometry, keep on-screen
end

-- Focus the nearest window in a direction ("West"/"East"/"North"/"South").
-- Hammerspoon's focusWindow* work in global screen coordinates, so this
-- crosses displays automatically.
function M.focusDir(direction)
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("no window", config.alertDuration)
    return
  end
  win["focusWindow" .. direction](win, nil, true, false)
end

-- Screen (un)plug hook. We read screens live everywhere, so there is nothing to
-- rebuild; kept so display changes have a home for future per-screen state.
M.screenWatcher = hs.screen.watcher.new(function() end)
M.screenWatcher:start()

return M
