-- init.lua — modular, hand-rolled Hammerspoon window manager.
--
-- Keeps native macOS Spaces/Mission Control; adds keyboard-driven window
-- snapping via a sticky "window mode" modal (Cmd+Ctrl+Space). Config lives in
-- the dotfiles repo and is symlinked to ~/.config/hammerspoon by GNU Stow.
--
-- See docs/ (Johnny Decimal). Module load order matters: leaf deps first.

-- Make lua/ modules requirable (hs.configdir = ~/.config/hammerspoon).
package.path = table.concat({
  package.path,
  hs.configdir .. "/lua/?.lua",
  hs.configdir .. "/lua/?/init.lua",
}, ";")

local config = require("config")

-- Lifecycle -----------------------------------------------------------------
hs.autoLaunch(true)                -- register the login item on first launch
hs.dockIcon(false)                 -- no Dock icon; menubar icon stays
hs.window.animationDuration = 0    -- instant snapping (native feel, no slide)

-- Managers (side effects: bind hotkeys, start watchers) ----------------------
require("float")     -- window-should-not-be-managed predicate
require("window")    -- frame operations
require("display")   -- multi-display move/focus + screen watcher
require("focus")     -- global directional focus hotkeys (no window mode)
require("modal")     -- window-mode modal + keymap
require("reload")    -- pathwatcher auto-reload + manual hotkey

hs.alert.show(config.startupText)
