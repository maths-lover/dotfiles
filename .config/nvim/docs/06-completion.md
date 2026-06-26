[Documentation index](README.md)

# 6. Completion

`blink.cmp` (in `lua/plugins/completion.lua`) provides fast, modern completion with
a prebuilt fuzzy-matching engine. Snippets come from `friendly-snippets`.

## Sources

In priority order: LSP, path, snippets, buffer.

## Keymaps (default preset)

| Key | Action |
|-----|--------|
| `<C-space>` | open completion menu / toggle docs |
| `<C-n>` / `<C-p>` | next / previous item |
| `<C-y>` | accept |
| `<C-e>` | hide menu |
| `<C-k>` | toggle signature help |
| `Tab` / `S-Tab` | jump forward / back in a snippet |

## Behavior

- Documentation auto-shows shortly after selecting an item.
- Ghost text previews the top suggestion inline.
- Signature help shows in a rounded window while typing arguments.
- The completion menu uses a rounded border, consistent with other floats.
- Nerd Font icons label item kinds (variant set to `mono`).

## Customizing

Edit `opts` in `lua/plugins/completion.lua`. To change sources, edit
`sources.default`. To change keys, switch the `keymap.preset` (for example to
`super-tab` or `enter`) or set explicit mappings. Snippets are standard LSP/LuaSnip
style via friendly-snippets; add your own under a snippets directory if desired.

---

Next: [Navigation & search](07-navigation.md)
