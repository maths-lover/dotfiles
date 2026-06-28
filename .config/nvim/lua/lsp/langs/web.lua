-- lua/lsp/langs/web.lua - JS/TS + HTML/CSS + ESLint (prettierd formats). Node via brew.
return {
  servers = {
    ts_ls = {},
    html = {},
    cssls = {},
    eslint = {},
  },
  tools = { "prettierd" },
}
