[Documentation index](README.md)

# 5. LSP & languages

Configured in `lua/plugins/lsp.lua` (servers) and `lua/plugins/formatting.lua`
(formatters). Servers and formatters are installed automatically by Mason.

## Supported languages

| Language | LSP server | Formatter(s) |
|----------|-----------|--------------|
| Lua | lua_ls | stylua |
| Bash / sh | bashls | shfmt |
| Markdown | marksman | prettier(d) |
| JSON / JSONC | jsonls | prettier(d) |
| YAML | yamlls | prettier(d) |
| TOML | taplo | taplo |
| Python | basedpyright + ruff | ruff (format + import sort) |
| JavaScript / TypeScript / JSX / TSX | ts_ls, eslint | prettier(d) |
| HTML / CSS | html, cssls | prettier(d) |
| Go | gopls | goimports + gofumpt |
| Rust | rust_analyzer | rustfmt |
| C / C++ | clangd | clang-format |
| Java | jdtls | google-java-format |
| Zig | zls | zigfmt |

Toolchains (node, go, rust, zig, openjdk; clang via Xcode CLT) come from the
Brewfile. Zig is pinned to the stable release so it matches the Mason `zls`.

## LSP keymaps (active when a server attaches)

| Key | Action |
|-----|--------|
| `gd` | definition (fzf-lua) |
| `gr` | references (fzf-lua) |
| `gI` | implementation |
| `gy` | type definition |
| `gD` | declaration |
| `K` | hover docs |
| `<leader>cr` | rename |
| `<leader>ca` | code action (normal/visual) |
| `<leader>cs` | document symbols |
| `<leader>ci` | toggle inlay hints |

Diagnostics navigation (`]d` / `[d`, `<leader>e`) is in [Keymaps](03-keymaps.md).

## Diagnostics

Configured with sorted severity, a rounded float that shows the source, Nerd Font
sign icons, and virtual text shown only when there are multiple sources on a line.
Open the line float with `<leader>e`.

## Formatting

`conform.nvim` formats on save (`BufWritePre`) and on demand with `<leader>cf`.
It falls back to LSP formatting when no dedicated formatter is configured.

Toggle format-on-save:

```vim
:FormatDisable      " whole session
:FormatDisable!     " current buffer only
:FormatEnable       " re-enable
```

## Per-server settings

A few servers have custom settings in `lua/plugins/lsp.lua`:

- `lua_ls` - LuaJIT runtime, recognizes the `vim` global, call snippets, hints.
- `gopls` - inlay hints for types, parameters, constants, etc.
- `basedpyright` - standard type-checking mode.

Add more with `vim.lsp.config("<server>", { settings = {...} })`. This config uses
the modern `vim.lsp.config` / `vim.lsp.enable` API (no deprecated calls).

## Notes

- `stylua` is a formatter; lspconfig also ships a `stylua --lsp` config, so it is
  excluded from `automatic_enable` to avoid starting it as a language server.
- blink.cmp extends the LSP client capabilities for richer completion.

---

Next: [Completion](06-completion.md)
