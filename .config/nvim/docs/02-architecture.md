[Documentation index](README.md)

# 2. Architecture

## File layout

```
~/.config/nvim/
|-- init.lua                 leader keys + load order
|-- lazy-lock.json           pinned plugin versions (tracked)
|-- lua/
|   |-- config/
|   |   |-- options.lua      vim.opt settings
|   |   |-- keymaps.lua      general keymaps
|   |   |-- autocmds.lua     autocommands
|   |   |-- lazy.lua         bootstrap lazy.nvim, load plugins
|   |   |-- theme.lua        colorscheme sync with the OS `theme`
|   |   `-- neovide.lua      GUI settings (Neovide only)
|   `-- plugins/             one file per area (see Plugins doc)
`-- docs/                    this documentation
```

## Load order

`init.lua` runs modules in this order:

1. set `mapleader` / `maplocalleader` (must be before lazy)
2. `config.options`
3. `config.keymaps`
4. `config.autocmds`
5. `config.neovide`  (self-guards; no-op outside Neovide)
6. `config.lazy`     (bootstraps lazy.nvim and imports `lua/plugins/*`)
7. `config.theme`    (applies the colorscheme synced to the OS theme)

Theme is applied last so it runs after the colorscheme plugins have loaded.

## How plugins are organized

`lua/config/lazy.lua` imports the whole `plugins` directory:

```lua
require("lazy").setup({ spec = { { import = "plugins" } }, ... })
```

Each file in `lua/plugins/` returns a lazy.nvim spec (a table, or a list of
tables). Files are grouped by area: `colorschemes`, `treesitter`, `lsp`,
`completion`, `formatting`, `fzf`, `git`, `editor`, `ui`. See [Plugins](04-plugins.md).

## Adding a plugin

Create or edit a file in `lua/plugins/`:

```lua
-- lua/plugins/myplugin.lua
return {
  { "owner/repo", event = "VeryLazy", opts = {} },
}
```

Then `:Lazy sync`. Because `~/.config/nvim` is a folded stow symlink into the repo,
the new file is already inside the repo - no extra `stow` needed.

## Adding a language

Three spots, all keyed by the language:

1. Treesitter parser -> add to `ensure_installed` in `lua/plugins/treesitter.lua`.
2. LSP server -> add to `ensure_installed` in `lua/plugins/lsp.lua` (Mason name).
   Add a `vim.lsp.config("<server>", {...})` block for custom settings if needed.
3. Formatter -> add to `formatters_by_ft` in `lua/plugins/formatting.lua` (and to
   mason-tool-installer's `ensure_installed` so it auto-installs).

Restart `nvim`; Mason installs the new server/formatter on next use.

## Options worth knowing

Set in `lua/config/options.lua`:

- `clipboard = unnamedplus` - yanks go to the macOS pasteboard.
- `undofile` on - persistent undo across sessions.
- `expandtab`, `shiftwidth=2` - 2-space indent default (LSP/formatters override per language).
- `ignorecase` + `smartcase` - smart search casing.
- `inccommand = split` - live preview of `:substitute`.
- `winborder = rounded` - rounded floating-window borders.
- `termguicolors` - 24-bit color for rich colorschemes.

---

Next: [Keymaps](03-keymaps.md)
