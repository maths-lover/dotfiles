-- lua/plugins/formatting.lua — conform.nvim (format on save + <leader>cf)
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        python = { "ruff_organize_imports", "ruff_format" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        go = { "goimports", "gofumpt" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        java = { "google-java-format" },
        zig = { "zigfmt" },
        toml = { "taplo" },
      },
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,
      formatters = { shfmt = { prepend_args = { "-i", "2", "-ci" } } },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
      vim.api.nvim_create_user_command("FormatDisable", function(a)
        if a.bang then vim.b.disable_autoformat = true else vim.g.disable_autoformat = true end
      end, { bang = true, desc = "Disable format-on-save (! = buffer only)" })
      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, { desc = "Re-enable format-on-save" })
    end,
  },
}
