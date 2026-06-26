-- lua/plugins/notes.lua - markdown notes / knowledge base
-- markdown_oxide (the LSP) is installed via Mason in lua/plugins/lsp.lua.
-- render-markdown gives a pretty in-editor view; obsidian.nvim manages the vault.
return {
  -- Pretty in-editor markdown rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      completions = { lsp = { enabled = true } },
    },
    keys = {
      { "<leader>nr", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown render" },
    },
  },

  -- Obsidian vault integration (maintained fork)
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = {
        -- Point this at your real Obsidian vault if you have one.
        { name = "notes", path = "~/notes" },
      },
      -- render-markdown.nvim handles the visual rendering.
      ui = { enable = false },
      legacy_commands = false,
    },
    keys = {
      { "<leader>nn", "<cmd>Obsidian new<cr>", desc = "New note" },
      { "<leader>ns", "<cmd>Obsidian search<cr>", desc = "Search notes" },
      { "<leader>nq", "<cmd>Obsidian quick_switch<cr>", desc = "Quick switch note" },
      { "<leader>nt", "<cmd>Obsidian today<cr>", desc = "Today's daily note" },
      { "<leader>nb", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>no", "<cmd>Obsidian open<cr>", desc = "Open in Obsidian app" },
    },
  },
}
