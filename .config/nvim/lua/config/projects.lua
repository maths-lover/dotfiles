-- lua/config/projects.lua - work on multiple projects in one Neovim instance.
--
-- Each project opens in its OWN tab with a tab-local working directory (:tcd),
-- so file-finding / grep / oil in that tab are scoped to that project. LSP is
-- already isolated per project automatically (each server roots at go.mod /
-- package.json / pyproject.toml / .git), so a Go tab and a Python tab each get
-- their own correctly-rooted server with no extra setup.
local M = {}

-- Open <dir> as a project in a new tab (tab-local cwd + file picker).
function M.open(dir)
  if not dir or dir == "" then return end
  dir = (vim.fn.fnamemodify(dir, ":p")):gsub("/$", "")
  vim.cmd("tabnew")
  vim.cmd("tcd " .. vim.fn.fnameescape(dir)) -- tab-local cwd
  local ok, fzf = pcall(require, "fzf-lua")
  if ok then
    fzf.files({ cwd = dir })
  else
    vim.cmd("edit " .. vim.fn.fnameescape(dir)) -- oil on the dir
  end
end

-- Pick a project from your zoxide history, open it in a new tab.
function M.pick()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.WARN)
    return
  end
  fzf.fzf_exec("zoxide query -l", {
    prompt = "Project> ",
    actions = { ["default"] = function(sel) M.open(sel and sel[1]) end },
  })
end

vim.api.nvim_create_user_command("Project", M.pick, { desc = "Open a project in a new tab" })

-- Keymaps: open a project, and move between project tabs.
local map = vim.keymap.set
map("n", "<leader>fp", M.pick, { desc = "Open project (new tab)" })
map("n", "<leader>tp", M.pick, { desc = "Open project (new tab)" })
map("n", "]t", "<cmd>tabnext<cr>", { desc = "Next tab (project)" })
map("n", "[t", "<cmd>tabprevious<cr>", { desc = "Prev tab (project)" })
map("n", "<leader>tx", "<cmd>tabclose<cr>", { desc = "Close tab (project)" })

return M
