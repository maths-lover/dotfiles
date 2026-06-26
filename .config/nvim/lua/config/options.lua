-- lua/config/options.lua — vim.opt settings
local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"          -- avoid text shift when signs appear
opt.cursorline = true
opt.termguicolors = true        -- 24-bit color (rich colorschemes)
opt.showmode = false            -- mode shown in statusline instead
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " " }
opt.pumheight = 12              -- completion menu height
opt.winborder = "rounded"      -- default border for floating windows (nvim 0.11+)

-- Editing
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.breakindent = true
opt.undofile = true            -- persistent undo
opt.swapfile = false
opt.confirm = true             -- ask to save instead of failing :q

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"       -- live preview of :s

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Behavior
opt.clipboard = "unnamedplus"  -- share with the macOS pasteboard
opt.mouse = "a"
opt.updatetime = 250
opt.timeoutlen = 400           -- which-key popup delay (vim mode uses KEYTIMEOUT in zsh)
opt.completeopt = "menu,menuone,noselect"

-- Diagnostics float/window look is configured in plugins/lsp.lua
vim.o.background = "dark"       -- default; theme.lua overrides per active theme
