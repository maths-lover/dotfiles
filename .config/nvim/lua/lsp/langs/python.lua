-- lua/lsp/langs/python.lua - Python via uv.
-- Type-checking + LSP: ty (Astral, Rust) - replaces basedpyright/pyright.
-- Linting + import sorting: ruff. Both are uv tools (`uv tool install ty ruff`),
-- so they are declared `system` (from PATH, not Mason).
--
-- ty auto-detects the project's .venv (uv's default layout) to resolve imports,
-- so no interpreter wiring is needed. Debugging uses nvim-dap-python with the
-- debugpy env from `uv tool install debugpy` (see the plugin below).
return {
  servers = {
    ty = {
      system = "ty",
      -- ty resolves imports from the project's .venv automatically. Project
      -- overrides go in pyproject.toml [tool.ty] or a ty.toml.
    },
    ruff = {
      system = "ruff",
      -- ruff owns linting + import sorting; let ty own hover/types.
      on_attach = function(client) client.server_capabilities.hoverProvider = false end,
    },
  },
  plugins = {
    {
      "mfussenegger/nvim-dap-python",
      ft = "python",
      dependencies = { "mfussenegger/nvim-dap" },
      config = function()
        -- The adapter runs from the dedicated debugpy env created by uv; the
        -- program being debugged still uses the project's own .venv (resolved
        -- automatically), so debugpy is NOT needed in every project.
        local py = vim.fn.expand("~/.local/share/uv/tools/debugpy/bin/python")
        if vim.fn.executable(py) ~= 1 then py = vim.fn.exepath("python3") end
        require("dap-python").setup(py)
        vim.keymap.set("n", "<leader>dn", function() require("dap-python").test_method() end,
          { desc = "Debug nearest test (python)" })
      end,
    },
  },
}
