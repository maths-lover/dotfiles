-- lua/lsp/langs/lua.lua - Lua (Neovim config dev).
return {
  servers = {
    lua_ls = {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
          diagnostics = { globals = { "vim" } },
          completion = { callSnippet = "Replace" },
          hint = { enable = true },
        },
      },
    },
  },
  tools = { "stylua" },
}
