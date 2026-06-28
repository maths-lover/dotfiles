-- lua/lsp/langs/flutter.lua - Dart / Flutter.
-- Dart's LSP (dartls) ships with the Flutter SDK, so it is managed by
-- flutter-tools.nvim rather than Mason. This module contributes a lazy plugin
-- spec (loaded only for dart files) instead of a `servers` entry. Needs the
-- Flutter SDK on PATH to actually start; harmless otherwise. Delete this file
-- if you do not work with Flutter.
return {
  plugins = {
    {
      "nvim-flutter/flutter-tools.nvim",
      ft = { "dart" },
      dependencies = { "nvim-lua/plenary.nvim" },
      opts = function()
        local caps = vim.lsp.protocol.make_client_capabilities()
        local ok, blink = pcall(require, "blink.cmp")
        if ok then caps = blink.get_lsp_capabilities(caps) end
        return {
          lsp = {
            capabilities = caps,
            color = { enabled = true }, -- render Color(...) swatches inline
            settings = {
              showTodos = true,
              completeFunctionCalls = true,
              renameFilesWithClasses = "prompt",
            },
          },
        }
      end,
    },
  },
}
