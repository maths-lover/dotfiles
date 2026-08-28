-- reload.lua — auto-reload on config change + a global manual-reload hotkey.
--
-- The config dir (~/.config/hammerspoon) is a GNU Stow SYMLINK into the repo, so
-- we resolve it to its real path before watching; otherwise FSEvents can miss
-- edits made through the symlink. Reloading re-runs init.lua, which re-shows the
-- startup alert.

local config = require("config")

local M = {}

-- Resolve symlinks (Stow) to the real repo path.
local realDir = hs.fs.pathToAbsolute(hs.configdir) or hs.configdir

M.watcher = hs.pathwatcher.new(realDir, function(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end)
M.watcher:start()

-- Global manual reload (also available as `r` inside window mode).
hs.hotkey.bind(config.reloadHotkey.mods, config.reloadHotkey.key, function()
  hs.reload()
end)

return M
