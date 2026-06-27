-- lua/plugins/editor.lua - editing ergonomics

-- Absolute path of the entry under the cursor in an oil buffer (or nil).
local function oil_path()
  local oil = require("oil")
  local dir, entry = oil.get_current_dir(), oil.get_cursor_entry()
  if dir and entry then return dir .. entry.name, entry end
end

return {
  -- Keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>c", group = "code" },
        { "<leader>h", group = "git hunks" },
        { "<leader>g", group = "git" },
        { "<leader>s", group = "splits" },
        { "<leader>b", group = "buffers" },
        { "<leader>o", group = "open (external)" },
        { "<leader>y", group = "yank/copy" },
        { "<leader>n", group = "notes" },
        { "<leader>t", group = "tabs/projects" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
    },
  },

  -- Autopairs
  { "echasnovski/mini.pairs", event = "InsertEnter", opts = {} },

  -- vim-surround (ys / cs / ds) - matches your zsh surround muscle memory
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },

  -- Better a/i text objects
  { "echasnovski/mini.ai", event = "VeryLazy", opts = {} },

  -- Edit the filesystem like a buffer
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent dir (oil)" },
      { "<leader>fe", "<cmd>Oil<cr>", desc = "File explorer (oil)" },
    },
    opts = {
      view_options = { show_hidden = true },
      keymaps = {
        ["q"] = "actions.close",
        -- Clipboard synergy (macOS): path / contents / file-reference
        ["gy"] = {
          desc = "Copy path to clipboard",
          callback = function()
            local p = oil_path()
            if p then vim.fn.setreg("+", p); vim.notify("Copied path: " .. p) end
          end,
        },
        ["gC"] = {
          desc = "Copy file contents to clipboard",
          callback = function()
            local p, e = oil_path()
            if p and e and e.type == "file" then
              local ok, lines = pcall(vim.fn.readfile, p)
              if ok then vim.fn.setreg("+", table.concat(lines, "\n")); vim.notify("Copied contents: " .. e.name) end
            end
          end,
        },
        ["gX"] = {
          desc = "Copy file to clipboard (paste into apps)",
          callback = function()
            local p, e = oil_path()
            if p then
              -- Put a file reference on the clipboard; pasting into Slack/Mail/
              -- Finder/etc. drops the actual file (great for images, reports).
              vim.system({ "osascript", "-e", 'set the clipboard to POSIX file "' .. p .. '"' })
              vim.notify("Copied file to clipboard: " .. (e and e.name or p))
            end
          end,
        },
        -- Open in external macOS apps
        ["<leader>oo"] = {
          desc = "Open entry in default app",
          callback = function()
            local p = oil_path(); if p then vim.ui.open(p) end
          end,
        },
        ["<leader>oF"] = {
          desc = "Reveal entry in Finder",
          callback = function()
            local p = oil_path(); if p then vim.system({ "open", "-R", p }) end
          end,
        },
      },
    },
  },

  -- Fast motions (`s` to jump)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
    },
  },
}
