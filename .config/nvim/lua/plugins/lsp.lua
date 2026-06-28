-- lua/plugins/lsp.lua - Mason + LSP wiring.
-- The actual configuration is MODULAR and lives in lua/lsp/: a core loader
-- (lua/lsp/init.lua) plus one file per tech stack in lua/lsp/langs/. To add or
-- tweak a stack, edit a file there - see the header of lua/lsp/init.lua.
local lsp = require("lsp")

local specs = {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("lsp").setup()
    end,
  },
}

-- Stacks can contribute their own plugins (e.g. flutter-tools for Dart).
vim.list_extend(specs, lsp.plugin_specs())

return specs
