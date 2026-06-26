[Documentation index](README.md)

# 1. Getting started

## Install

This config is part of the dotfiles repo and is symlinked into place by GNU Stow:

```sh
git clone <your-dotfiles-repo> ~/dotfiles
~/dotfiles/install.sh        # stows ~/.config/nvim and installs toolchains
```

`~/.config/nvim` is a symlink to `~/dotfiles/.config/nvim`, so edits to the config
are edits to the repo. The language toolchains (node, go, rust, zig, openjdk; clang
via Xcode CLT) are installed from the Brewfile by the installer.

## First launch

Just run `nvim`. On the first start the config bootstraps itself:

1. lazy.nvim is cloned automatically (see `lua/config/lazy.lua`).
2. All plugins are installed.
3. Treesitter parsers compile.
4. Mason installs the language servers and formatters listed in
   `lua/plugins/lsp.lua` and `lua/plugins/formatting.lua`.

Give it a minute on the very first run. Watch progress with `:Lazy` (plugins) and
`:Mason` (servers/tools). After that, startup is fast.

## What auto-installs

| Thing | Where it is declared | Manage with |
|-------|----------------------|-------------|
| Plugins | `lua/plugins/*.lua` | `:Lazy` |
| Treesitter parsers | `lua/plugins/treesitter.lua` | `:TSUpdate` |
| LSP servers | `ensure_installed` in `lua/plugins/lsp.lua` | `:Mason` |
| Formatters | `lua/plugins/formatting.lua` + mason-tool-installer | `:Mason` |

## Health check

```vim
:checkhealth
```

Confirms Neovim version, providers, treesitter, lazy, and Mason tool status.

## Reloading after edits

| Edited | Apply with |
|--------|-----------|
| any Lua under `lua/` | restart `nvim` (config is read at startup) |
| a plugin spec | `:Lazy sync` (install/update/clean to match specs) |
| colorscheme out of sync with terminal | `:ThemeSync` |

## Updating

```vim
:Lazy sync       " update plugins to match lazy-lock.json / specs
:Mason           " update servers/formatters
:TSUpdate        " update treesitter parsers
```

`lazy-lock.json` pins plugin versions and is tracked in the repo, so installs are
reproducible across machines.

---

Next: [Architecture](02-architecture.md)
