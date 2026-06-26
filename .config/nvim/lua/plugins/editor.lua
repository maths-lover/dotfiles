-- lua/plugins/editor.lua - editing ergonomics
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
      keymaps = { ["q"] = "actions.close" },
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
