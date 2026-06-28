-- lua/lsp/langs/markdown.lua - Markdown notes via markdown-oxide (Homebrew, not
-- Mason): links, backlinks, daily notes. Declared `system` so it is enabled only
-- when the binary is present and never auto-started by Mason.
return {
  servers = {
    markdown_oxide = { system = "markdown-oxide" },
  },
}
