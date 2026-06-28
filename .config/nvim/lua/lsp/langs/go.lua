-- lua/lsp/langs/go.lua - Go (gopls + gofumpt/goimports). Toolchain via brew "go".
return {
  servers = {
    gopls = {
      settings = {
        gopls = {
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            constantValues = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
        },
      },
    },
  },
  tools = { "gofumpt", "goimports" },
}
