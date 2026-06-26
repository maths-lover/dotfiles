[Documentation index](README.md)

# 4. Plugins

Managed by lazy.nvim. Each file in `lua/plugins/` owns one area. Open the Lazy UI
with `<leader>l` or `:Lazy`.

## colorschemes.lua

tokyonight, catppuccin, gruvbox, dracula, rose-pine. All load at high priority so
the theme-sync (see [Theme sync](09-theme-sync.md)) can select one at startup.

## treesitter.lua

`nvim-treesitter` (master) + `nvim-treesitter-textobjects`. Highlighting, indent,
incremental selection, and text objects. Parsers auto-install. See
[Navigation](07-navigation.md) for the text-object keymaps.

## lsp.lua

`nvim-lspconfig` + Mason (`mason.nvim`, `mason-lspconfig.nvim`,
`mason-tool-installer.nvim`) + blink capabilities. See [LSP & languages](05-lsp-and-languages.md).

## completion.lua

`blink.cmp` + `friendly-snippets`. See [Completion](06-completion.md).

## formatting.lua

`conform.nvim` - format on save and `<leader>cf`. See [LSP & languages](05-lsp-and-languages.md).

## fzf.lua

`fzf-lua` - fuzzy finder matching the terminal fzf workflow. See [Navigation](07-navigation.md).

## git.lua

`gitsigns.nvim` + `lazygit.nvim`. See [Git](08-git.md).

## editor.lua

Editing ergonomics:

| Plugin | What it gives you |
|--------|-------------------|
| `which-key.nvim` | popup of pending keymaps (helix preset); `<leader>?` for buffer maps |
| `mini.pairs` | auto-close brackets/quotes |
| `nvim-surround` | `ys` / `cs` / `ds` to add/change/delete surroundings |
| `mini.ai` | smarter `a`/`i` text objects |
| `oil.nvim` | edit the filesystem like a buffer (`-` to open parent) |
| `flash.nvim` | `s` / `S` motions to jump anywhere |

## ui.lua

| Plugin | What it gives you |
|--------|-------------------|
| `nvim-web-devicons` | file-type icons (Nerd Font) |
| `lualine.nvim` | statusline; `theme = auto` so it follows the colorscheme |
| `indent-blankline.nvim` | indent guides with active-scope highlight |

## Performance

`lua/config/lazy.lua` disables unused built-in plugins (gzip, tar, zip, tutor,
netrw, tohtml) and runs background update checks quietly. Most plugins load on an
event (`VeryLazy`, `BufReadPre`, `InsertEnter`) or a key/command, not at startup.

---

Next: [LSP & languages](05-lsp-and-languages.md)
