-- lua/lsp/langs/rust.lua - Rust (rust-analyzer). Toolchain + rustfmt via brew "rust".
-- rustfmt ships with the toolchain; conform calls it directly (no Mason tool).
return {
  servers = {
    rust_analyzer = {
      -- Uncomment to lint with clippy on save and see all-feature analysis:
      -- settings = {
      --   ["rust-analyzer"] = {
      --     check = { command = "clippy" },
      --     cargo = { allFeatures = true },
      --   },
      -- },
    },
  },
}
