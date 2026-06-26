-- lua/config/theme.lua - keep neovim's colorscheme in sync with the OS `theme`
-- switcher. The zsh `theme` command writes the active theme name to
-- ~/.config/zsh/.active-theme; we map it to a matching nvim colorscheme.
local M = {}

local state_file = vim.fn.expand("~/.config/zsh/.active-theme")

-- zsh theme alias -> { nvim colorscheme, background }
local MAP = {
  tokyonight        = { "tokyonight-night", "dark" },
  ["tokyonight-day"] = { "tokyonight-day", "light" },
  dracula           = { "dracula", "dark" },
  gruvbox           = { "gruvbox", "dark" },
  ["gruvbox-light"] = { "gruvbox", "light" },
  latte             = { "catppuccin-latte", "light" },
  mocha             = { "catppuccin-mocha", "dark" },
  ["rose-pine"]     = { "rose-pine", "dark" },
  ["rose-pine-dawn"] = { "rose-pine-dawn", "light" },
  ["github-light"]  = { "rose-pine-dawn", "light" },
  -- terminal-only neon/green themes -> closest rich nvim scheme
  cyberpunk         = { "tokyonight-night", "dark" },
  homebrew          = { "tokyonight-night", "dark" },
  matrix            = { "tokyonight-night", "dark" },
}

local DEFAULT = { "tokyonight-night", "dark" }
local applied -- guard against redundant re-applies

local function read_theme()
  local f = io.open(state_file, "r")
  if not f then return nil end
  local name = f:read("l")
  f:close()
  if name then name = name:gsub("%s+", "") end
  if not name or name == "" then return nil end
  return name
end

-- Resolve any theme name (alias OR full Ghostty name, any case) to a scheme.
local function resolve(name)
  if not name then return DEFAULT end
  if MAP[name] then return MAP[name] end
  local n = name:lower()
  local function has(p) return n:find(p, 1, true) ~= nil end
  local light = has("light") or has("day") or has("dawn") or has("latte") or has("dayfox")
  local scheme
  if has("rose") then
    scheme = light and "rose-pine-dawn" or "rose-pine"
  elseif has("gruvbox") then
    scheme = "gruvbox"
  elseif has("dracula") then
    scheme = "dracula"
  elseif has("catppuccin") or has("latte") or has("mocha") or has("frappe") or has("macchiato") then
    scheme = light and "catppuccin-latte" or "catppuccin-mocha"
  elseif has("tokyo") then
    scheme = light and "tokyonight-day" or "tokyonight-night"
  else
    scheme = light and "tokyonight-day" or DEFAULT[1]
  end
  return { scheme, light and "light" or "dark" }
end

function M.apply(name)
  local r = resolve(name or read_theme())
  local scheme, bg = r[1], r[2]
  if applied == scheme .. ":" .. bg then return end
  vim.o.background = bg
  if not pcall(vim.cmd.colorscheme, scheme) then
    pcall(vim.cmd.colorscheme, DEFAULT[1])
  end
  applied = scheme .. ":" .. bg
end

function M.setup()
  M.apply()

  -- Re-sync when nvim regains focus (covers terminal `theme x` while away).
  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("theme_sync", { clear = true }),
    callback = function() M.apply() end,
  })

  -- Live-watch the state file for instant updates.
  local ok, watcher = pcall(vim.uv.new_fs_event)
  if ok and watcher then
    pcall(watcher.start, watcher, state_file, {}, vim.schedule_wrap(function()
      M.apply()
    end))
  end

  vim.api.nvim_create_user_command("ThemeSync", function()
    applied = nil
    M.apply()
  end, { desc = "Re-sync colorscheme with the OS theme" })
end

return M
