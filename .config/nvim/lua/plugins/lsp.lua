-- lua/plugins/lsp.lua - Mason + LSP (modern vim.lsp.config / vim.lsp.enable API)
return {
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
      -- Diagnostics UI
      vim.diagnostic.config({
        severity_sort = true,
        float = { border = "rounded", source = true },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = " ",
          },
        },
        virtual_text = { spacing = 2, source = "if_many" },
      })

      -- Capabilities: blink.cmp extends the defaults for richer completion
      local caps = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then caps = blink.get_lsp_capabilities(caps) end
      vim.lsp.config("*", { capabilities = caps })

      -- Buffer-local keymaps when a server attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local ok_fzf, fzf = pcall(require, "fzf-lua")
          local function m(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
          end
          m("gd", ok_fzf and fzf.lsp_definitions or vim.lsp.buf.definition, "Definition")
          m("gr", ok_fzf and fzf.lsp_references or vim.lsp.buf.references, "References")
          m("gI", ok_fzf and fzf.lsp_implementations or vim.lsp.buf.implementation, "Implementation")
          m("gy", ok_fzf and fzf.lsp_typedefs or vim.lsp.buf.type_definition, "Type definition")
          m("gD", vim.lsp.buf.declaration, "Declaration")
          m("K", function() vim.lsp.buf.hover() end, "Hover")
          m("<leader>cr", vim.lsp.buf.rename, "Rename")
          m("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })
          m("<leader>cs", ok_fzf and fzf.lsp_document_symbols or vim.lsp.buf.document_symbol, "Symbols")
          if vim.lsp.inlay_hint then
            m("<leader>ci", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
            end, "Toggle inlay hints")
          end
        end,
      })

      -- Per-server settings (merged with the defaults above)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
            diagnostics = { globals = { "vim" } },
            completion = { callSnippet = "Replace" },
            hint = { enable = true },
          },
        },
      })
      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            hints = {
              assignVariableTypes = true, compositeLiteralFields = true,
              constantValues = true, parameterNames = true, rangeVariableTypes = true,
            },
          },
        },
      })
      vim.lsp.config("basedpyright", {
        settings = { basedpyright = { analysis = { typeCheckingMode = "standard" } } },
      })

      -- Install servers + tools; mason-lspconfig auto-enables installed servers.
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", "bashls", "marksman", "jsonls", "yamlls", "taplo",
          "basedpyright", "ruff", "ts_ls", "html", "cssls", "eslint",
          "gopls", "rust_analyzer", "clangd", "jdtls", "zls",
        },
        -- stylua is a formatter (installed below) but lspconfig ships a stylua
        -- "--lsp" config; exclude it so it isn't auto-started as a language server.
        automatic_enable = { exclude = { "stylua" } },
      })
      require("mason-tool-installer").setup({
        ensure_installed = {
          "stylua", "shfmt", "prettierd", "gofumpt", "goimports",
          "clang-format", "google-java-format",
        },
      })
    end,
  },
}
