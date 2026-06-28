-- lua/config/keymaps.lua - general keymaps (plugin keymaps live with their specs)
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlight" })

-- Save / quit
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit all (force)" })

-- Window navigation (matches zsh Ctrl-h/j/k/l muscle memory)
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize with arrows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Splits
map("n", "<leader>sv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>sc", "<cmd>close<cr>", { desc = "Close split" })

-- Buffers
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Move lines up/down (visual + normal)
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Keep selection when indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Center on scroll / search
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Paste over selection without yanking it
map("x", "<leader>p", [["_dP]], { desc = "Paste (keep register)" })

-- Move by screen line when wrapping (counts still move by file line: 5j works)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down (screen line)" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up (screen line)" })

-- Diagnostics navigation (all severities, then error- and warning-specific)
local S = vim.diagnostic.severity
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })
map("n", "]e", function() vim.diagnostic.jump({ count = 1, severity = S.ERROR }) end, { desc = "Next error" })
map("n", "[e", function() vim.diagnostic.jump({ count = -1, severity = S.ERROR }) end, { desc = "Prev error" })
map("n", "]w", function() vim.diagnostic.jump({ count = 1, severity = S.WARN }) end, { desc = "Next warning" })
map("n", "[w", function() vim.diagnostic.jump({ count = -1, severity = S.WARN }) end, { desc = "Prev warning" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Make treesitter motions (]f [f ]a [a ]c [c ...) repeatable with ; and , -
-- and fold the builtin f/t/F/T into the same repeat so ; , stay useful for them.
-- Deferred so it runs after treesitter (a start plugin) has loaded.
vim.schedule(function()
  local ok, tsrepeat = pcall(require, "nvim-treesitter.textobjects.repeatable_move")
  if not ok then return end
  map({ "n", "x", "o" }, ";", tsrepeat.repeat_last_move_next, { desc = "Repeat move (forward)" })
  map({ "n", "x", "o" }, ",", tsrepeat.repeat_last_move_previous, { desc = "Repeat move (backward)" })
  map({ "n", "x", "o" }, "f", tsrepeat.builtin_f_expr, { expr = true })
  map({ "n", "x", "o" }, "F", tsrepeat.builtin_F_expr, { expr = true })
  map({ "n", "x", "o" }, "t", tsrepeat.builtin_t_expr, { expr = true })
  map({ "n", "x", "o" }, "T", tsrepeat.builtin_T_expr, { expr = true })
end)

-- Open in external macOS apps (the download-report -> Excel move)
map("n", "<leader>oo", function() vim.ui.open(vim.fn.expand("%:p")) end, { desc = "Open file in default app" })
map("n", "<leader>od", function() vim.ui.open(vim.fn.expand("%:p:h")) end, { desc = "Open folder in default app" })
map("n", "<leader>oF", function() vim.system({ "open", "-R", vim.fn.expand("%:p") }) end, { desc = "Reveal in Finder" })

-- Copy paths to the system clipboard (clipboard=unnamedplus -> macOS pasteboard)
map("n", "<leader>yp", function()
  local p = vim.fn.expand("%:p"); vim.fn.setreg("+", p); vim.notify("Copied path: " .. p)
end, { desc = "Copy absolute path" })
map("n", "<leader>yr", function()
  local p = vim.fn.expand("%:~:."); vim.fn.setreg("+", p); vim.notify("Copied path: " .. p)
end, { desc = "Copy relative path" })
map("n", "<leader>yn", function()
  local p = vim.fn.expand("%:t"); vim.fn.setreg("+", p); vim.notify("Copied name: " .. p)
end, { desc = "Copy file name" })
