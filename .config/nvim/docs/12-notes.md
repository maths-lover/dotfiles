[Documentation index](README.md)

# 13. Notes (markdown)

A markdown notes / knowledge-base stack, configured in `lua/plugins/notes.lua`.

## Pieces

| Tool | Role |
|------|------|
| markdown_oxide (LSP) | links between notes, completion for `[[wikilinks]]` and `#tags`, backlinks, daily notes, rename - installed via Mason (see [LSP](05-lsp-and-languages.md)) |
| render-markdown.nvim | pretty in-editor rendering (headings, lists, code blocks, tables) |
| obsidian.nvim | vault management: new/search/daily notes, open in the Obsidian app |

markdown_oxide replaces marksman as the markdown LSP. Completion flows through
blink, so `[[` and `#` suggestions appear as you type.

## Vault

The Obsidian workspace defaults to `~/notes`. Point it at your real vault by editing
the `workspaces` path in `lua/plugins/notes.lua`.

## Keymaps (markdown buffers)

| Key | Action |
|-----|--------|
| `<leader>nn` | new note |
| `<leader>ns` | search notes |
| `<leader>nq` | quick-switch note |
| `<leader>nt` | today's daily note |
| `<leader>nb` | backlinks to this note |
| `<leader>no` | open the note in the Obsidian app |
| `<leader>nr` | toggle markdown rendering |

Following a `[[link]]` (go-to-definition, `gd`) and backlinks come from the
markdown_oxide LSP.

## Editing behavior

Markdown buffers get prose-friendly settings (in `lua/config/autocmds.lua`):
`conceallevel=2` (so render-markdown/obsidian can hide raw syntax), soft `wrap`
with `linebreak`, and `spell` checking.

---

Next: [Troubleshooting](13-troubleshooting.md)
