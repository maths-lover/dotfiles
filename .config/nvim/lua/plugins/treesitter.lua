-- lua/plugins/treesitter.lua - syntax-aware highlighting, indent, text objects
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    -- Pin textobjects to master: it matches nvim-treesitter's master API
    -- (configured below via opts.textobjects). Its default "main" branch is a
    -- rewrite that ignores this config, which silently disables the keymaps.
    dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" } },
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
          goto_next_start = { ["]f"] = "@function.outer", ["]a"] = "@parameter.inner", ["]c"] = "@class.outer" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[a"] = "@parameter.inner", ["[c"] = "@class.outer" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
        },
        -- Swap a parameter with the next/previous one (quick argument reordering).
        swap = {
          enable = true,
          swap_next = { ["<leader>a"] = "@parameter.inner" },
          swap_previous = { ["<leader>A"] = "@parameter.inner" },
        },
      },
    },
  },
  -- Pin the current function/class signature to the top while scrolling its body.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3, multiline_threshold = 1 },
    keys = {
      { "<leader>uc", "<cmd>TSContextToggle<cr>", desc = "Toggle sticky context" },
    },
  },
}
