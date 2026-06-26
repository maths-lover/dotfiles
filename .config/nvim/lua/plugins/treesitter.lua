-- lua/plugins/treesitter.lua - syntax-aware highlighting, indent, text objects
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = {
      ensure_installed = {
        "lua", "luadoc", "vim", "vimdoc", "query",
        "bash", "markdown", "markdown_inline", "json", "jsonc", "yaml", "toml",
        "python", "javascript", "typescript", "tsx", "html", "css",
        "go", "gomod", "gosum", "gowork", "rust", "c", "cpp", "java", "zig",
        "regex", "diff", "gitcommit", "git_rebase", "gitignore", "dockerfile",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          node_decremental = "<bs>",
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer", ["if"] = "@function.inner",
            ["ac"] = "@class.outer", ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer", ["ia"] = "@parameter.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]a"] = "@parameter.inner" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[a"] = "@parameter.inner" },
        },
      },
    },
  },
}
