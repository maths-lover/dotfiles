-- lua/plugins/colorschemes.lua
-- The schemes the OS `theme` switcher maps to (see lua/config/theme.lua).
-- All load eagerly (priority high) so theme.setup() can pick one at startup.
return {
  { "folke/tokyonight.nvim", priority = 1000, opts = { style = "night" } },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, opts = { flavour = "auto" } },
  { "ellisonleao/gruvbox.nvim", priority = 1000, opts = { contrast = "hard" } },
  { "Mofiqul/dracula.nvim", priority = 1000 },
  { "rose-pine/neovim", name = "rose-pine", priority = 1000 },
}
