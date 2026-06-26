[Documentation index](README.md)

# 12. macOS integration

Keymaps that bridge Neovim and the rest of macOS - opening files in native apps and
moving data to the system clipboard. The "Neovim feels native" pieces.

## Open in external apps

Works on the current buffer (normal mode) and on the entry under the cursor in oil.

| Key | Action |
|-----|--------|
| `<leader>oo` | open file in its default macOS app (CSV -> Numbers/Excel, PDF -> Preview, ...) |
| `<leader>od` | open the file's folder |
| `<leader>oF` | reveal the file in Finder |

Backed by `vim.ui.open` and `open -R`. In oil, `<leader>oo` / `<leader>oF` act on
the highlighted entry.

## Copy paths to the clipboard

The clipboard is shared with the macOS pasteboard (`clipboard=unnamedplus`).

| Key | Action |
|-----|--------|
| `<leader>yp` | copy absolute path |
| `<leader>yr` | copy path relative to cwd |
| `<leader>yn` | copy file name |

## Clipboard synergy in oil

Acting on the entry under the cursor in an oil buffer:

| Key | Action |
|-----|--------|
| `gy` | copy the entry's absolute path |
| `gC` | copy the file's contents |
| `gX` | copy the file itself to the clipboard (paste into Slack/Mail/Finder/etc. drops the actual file) |

`gX` puts a file reference on the clipboard via `osascript`, so pasting into apps
that accept files (including images and reports) just works.

---

Next: [Notes](12-notes.md)
