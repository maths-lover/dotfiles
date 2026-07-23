-- lua/plugins/treesitter.lua - syntax-aware highlighting, indent, text objects
-- Uses nvim-treesitter's rewritten "main" branch: the frozen "master" branch
-- pins parsers that crash Neovim 0.12+ on markdown fenced code blocks
-- ("attempt to call method 'range' (a nil value)"; neovim/neovim#39032).

local parsers = {
  "lua", "luadoc", "vim", "vimdoc", "query",
  "bash", "markdown", "markdown_inline", "json", "yaml", "toml",
  "python", "javascript", "typescript", "tsx", "html", "css",
  "go", "gomod", "gosum", "gowork", "rust", "c", "cpp", "java", "zig",
  "regex", "diff", "gitcommit", "git_rebase", "gitignore", "dockerfile",
}

-- <C-space> incremental selection shim: the main branch dropped the module,
-- so grow/shrink the visual selection along the node's ancestor chain here.
local sel_stack = {}
local function select_node(node)
  local sr, sc, er, ec = node:range()
  ec = ec == 0 and 1 or ec -- node ends at col 0 of the next line
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  vim.cmd.normal({ vim.fn.mode() == "v" and "o" or "v", bang = true })
  vim.api.nvim_win_set_cursor(0, { er + 1, ec - 1 })
end
local function select_init()
  local node = vim.treesitter.get_node()
  if not node then return end
  sel_stack = { node }
  select_node(node)
end
local function select_grow()
  local node = sel_stack[#sel_stack]
  if not node then return select_init() end
  local parent = node:parent()
  while parent and vim.deep_equal({ parent:range() }, { node:range() }) do
    node, parent = parent, parent:parent()
  end
  if not parent then return end
  table.insert(sel_stack, parent)
  select_node(parent)
end
local function select_shrink()
  if #sel_stack <= 1 then return end
  table.remove(sel_stack)
  select_node(sel_stack[#sel_stack])
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter").install(parsers)
      -- Highlighting + indent are opt-in per buffer on main: start them for
      -- any filetype whose parser is available (auto-installs missing ones).
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
          if not pcall(vim.treesitter.start, ev.buf, lang) then
            -- Auto-install on first use, but only languages that exist on
            -- main (avoids a warning per buffer for parserless filetypes).
            if vim.tbl_contains(require("nvim-treesitter.config").get_available(), lang) then
              require("nvim-treesitter").install({ lang })
            end
            return
          end
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
      vim.keymap.set("n", "<C-space>", select_init, { desc = "TS init selection" })
      vim.keymap.set("x", "<C-space>", select_grow, { desc = "TS grow selection" })
      vim.keymap.set("x", "<bs>", select_shrink, { desc = "TS shrink selection" })
    end,
  },

  -- Text objects (select/move/swap) - main branch: keymaps are set manually.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })
      local sel = require("nvim-treesitter-textobjects.select")
      for lhs, obj in pairs({
        ["af"] = "@function.outer", ["if"] = "@function.inner",
        ["ac"] = "@class.outer", ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer", ["ia"] = "@parameter.inner",
      }) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          sel.select_textobject(obj, "textobjects")
        end, { desc = "TS select " .. obj })
      end
      local move = require("nvim-treesitter-textobjects.move")
      local moves = {
        goto_next_start = { ["]f"] = "@function.outer", ["]a"] = "@parameter.inner", ["]c"] = "@class.outer" },
        goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[a"] = "@parameter.inner", ["[c"] = "@class.outer" },
        goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
      }
      for fn, maps in pairs(moves) do
        for lhs, obj in pairs(maps) do
          vim.keymap.set({ "n", "x", "o" }, lhs, function()
            move[fn](obj, "textobjects")
          end, { desc = "TS " .. fn .. " " .. obj })
        end
      end
      -- Swap a parameter with the next/previous one (quick argument reordering).
      local swap = require("nvim-treesitter-textobjects.swap")
      vim.keymap.set("n", "<leader>a", function() swap.swap_next("@parameter.inner") end, { desc = "Swap param with next" })
      vim.keymap.set("n", "<leader>A", function() swap.swap_previous("@parameter.inner") end, { desc = "Swap param with previous" })
    end,
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
