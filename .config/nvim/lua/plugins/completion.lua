-- lua/plugins/completion.lua — blink.cmp (fast, modern completion)
return {
  {
    "saghen/blink.cmp",
    version = "*", -- use the prebuilt fuzzy-matching binary
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "default" }, -- C-space open, C-y accept, C-n/C-p select, C-e hide
      appearance = { nerd_font_variant = "mono" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        menu = { border = "rounded" },
        ghost_text = { enabled = true },
      },
      signature = { enabled = true, window = { border = "rounded" } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
