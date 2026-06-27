-- ~/.config/nvim/init.lua
-- Modular neovim config. See lua/config/ (settings) and lua/plugins/ (one file
-- per area). Theme follows the OS `theme` switcher; works in terminal & Neovide.

-- Leader keys MUST be set before lazy.nvim loads.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.tabline")  -- per-project tab labels
require("config.neovide")  -- self-guards; no-op outside Neovide
require("config.lazy")     -- bootstraps lazy.nvim + loads lua/plugins/*
require("config.projects") -- multi-project: open a project per tab (<leader>fp)

-- Apply the colorscheme synced to the OS theme (after colorschemes are loaded).
require("config.theme").setup()
