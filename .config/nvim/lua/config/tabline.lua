-- lua/config/tabline.lua - show one entry per tab, labeled by that tab's project
-- directory (its tab-local cwd). Only appears when more than one tab is open, so
-- single-project use stays clutter-free.

function _G.NvProjectTabline()
  local s = ""
  local cur = vim.fn.tabpagenr()
  for i = 1, vim.fn.tabpagenr("$") do
    local cwd = vim.fn.getcwd(-1, i) -- tab-local cwd (-1 = tab scope)
    local name = vim.fn.fnamemodify(cwd, ":t")
    if name == "" then name = "/" end
    local hl = (i == cur) and "%#TabLineSel#" or "%#TabLine#"
    s = s .. hl .. "%" .. i .. "T" .. "  " .. i .. ":" .. name .. "  "
  end
  return s .. "%#TabLineFill#%T"
end

vim.o.tabline = "%!v:lua.NvProjectTabline()"
vim.o.showtabline = 1 -- show only when 2+ tabs exist
