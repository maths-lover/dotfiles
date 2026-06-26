-- lua/plugins/fzf.lua — fzf-lua (matches your terminal fzf workflow)
return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    keys = {
      { "<leader><space>", "<cmd>FzfLua files<cr>", desc = "Find files" },
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
      { "<leader>fw", "<cmd>FzfLua grep_cword<cr>", desc = "Grep word under cursor" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
      { "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Help tags" },
      { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
      { "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Diagnostics" },
      { "<leader>fc", "<cmd>FzfLua resume<cr>", desc = "Resume last" },
      { "<leader>/", "<cmd>FzfLua blines<cr>", desc = "Search buffer" },
      { "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git commits" },
      { "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git status" },
    },
    opts = {
      "default-title",
      fzf_colors = true, -- derive colors from the colorscheme → matches theme
      winopts = {
        height = 0.85,
        width = 0.85,
        preview = { default = "bat", scrollbar = "float" },
      },
    },
  },
}
