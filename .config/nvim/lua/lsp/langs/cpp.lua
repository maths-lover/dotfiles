-- lua/lsp/langs/cpp.lua - C / C++ (clangd + clang-format). clang via Xcode CLT.
return {
  servers = {
    clangd = {
      -- clangd reads compile_commands.json / .clangd; defaults are sensible.
    },
  },
  tools = { "clang-format" },
}
