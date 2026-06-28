-- lua/lsp/langs/shell.lua - Bash/sh (bash-language-server + shfmt).
return {
  servers = {
    bashls = {},
  },
  tools = { "shfmt" },
}
