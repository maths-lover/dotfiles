-- lua/config/autocmds.lua
local function augroup(name)
  return vim.api.nvim_create_augroup("cfg_" .. name, { clear = true })
end

-- Highlight yanked text (vim.hl.hl_op - current API; replaces vim.highlight.on_yank)
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("yank_highlight"),
  callback = function() vim.hl.hl_op({ higroup = "IncSearch", timeout = 150 }) end,
})

-- Restore last cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(ev)
    local exclude = { "gitcommit", "gitrebase" }
    if vim.tbl_contains(exclude, vim.bo[ev.buf].filetype) then return end
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto-resize splits when the window is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function() vim.cmd("tabdo wincmd =") end,
})

-- Close some utility buffers with `q`
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "gitsigns-blame" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- Don't auto-comment the next line on o/O
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("no_auto_comment"),
  callback = function() vim.opt_local.formatoptions:remove({ "o" }) end,
})

-- Prose-friendly settings for markdown notes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("markdown_prose"),
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 2 -- let render-markdown/obsidian hide syntax
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true -- wrap at word boundaries
    vim.opt_local.spell = true
  end,
})

-- Create missing parent directories when saving a new file
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(ev)
    if ev.match:match("^%w%w+://") then return end -- skip oil://, fugitive:// etc.
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Big-file guard: files over ~1.5 MB get the 'bigfile' filetype, which keeps
-- treesitter/LSP/illuminate off so giant logs or minified blobs stay responsive.
vim.g.bigfile_size = 1024 * 1024 * 1.5
vim.filetype.add({
  pattern = {
    [".*"] = {
      function(path, buf)
        return vim.bo[buf]
            and vim.bo[buf].filetype ~= "bigfile"
            and path
            and vim.fn.getfsize(path) > vim.g.bigfile_size
            and "bigfile"
          or nil
      end,
    },
  },
})
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("bigfile"),
  pattern = "bigfile",
  callback = function(ev)
    vim.schedule(function()
      vim.bo[ev.buf].syntax = vim.filetype.match({ buf = ev.buf }) or ""
    end)
  end,
})
