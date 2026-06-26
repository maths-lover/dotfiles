-- lua/config/neovide.lua — GUI settings, applied only inside Neovide.
if not vim.g.neovide then return end

-- Font (Monaspace Nerd Font, same as the terminal)
vim.o.guifont = "MonaspiceNe Nerd Font Mono:h14"

-- Padding (mirrors Ghostty)
vim.g.neovide_padding_top = 8
vim.g.neovide_padding_bottom = 8
vim.g.neovide_padding_left = 10
vim.g.neovide_padding_right = 10

-- Opacity (subtle, like the terminal's 0.96)
vim.g.neovide_opacity = 0.97
vim.g.neovide_normal_opacity = 0.97

-- Animations (snappy but smooth)
vim.g.neovide_cursor_animation_length = 0.06
vim.g.neovide_cursor_trail_size = 0.5
vim.g.neovide_cursor_vfx_mode = "railgun"
vim.g.neovide_scroll_animation_length = 0.20
vim.g.neovide_position_animation_length = 0.10

-- Window / UX
vim.g.neovide_remember_window_size = true
vim.g.neovide_hide_mouse_when_typing = true
vim.g.neovide_floating_blur_amount_x = 2.0
vim.g.neovide_floating_blur_amount_y = 2.0
vim.g.neovide_floating_shadow = true

-- macOS: left Option → Meta (so <A-…> mappings work), right Option for typing
vim.g.neovide_input_macos_option_key_is_meta = "only_left"

-- Native macOS clipboard shortcuts
local map = vim.keymap.set
map({ "n", "v" }, "<D-c>", '"+y', { desc = "Copy" })
map({ "n", "v" }, "<D-v>", '"+p', { desc = "Paste" })
map("i", "<D-v>", "<C-r>+", { desc = "Paste" })
map("c", "<D-v>", "<C-r>+", { desc = "Paste" })
map("n", "<D-s>", "<cmd>write<cr>", { desc = "Save" })
map("n", "<D-a>", "ggVG", { desc = "Select all" })

-- Cmd +/-/0 to zoom
vim.g.neovide_scale_factor = 1.0
local function scale(by) vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * by end
map("n", "<D-=>", function() scale(1.1) end, { desc = "Zoom in" })
map("n", "<D-->", function() scale(1 / 1.1) end, { desc = "Zoom out" })
map("n", "<D-0>", function() vim.g.neovide_scale_factor = 1.0 end, { desc = "Reset zoom" })
