-- lua/plugins/git.lua - gitsigns + lazygit (you already use lazygit in the shell)
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function m(keys, fn, desc, mode)
          vim.keymap.set(mode or "n", keys, fn, { buffer = buf, desc = desc })
        end
        m("]h", function() gs.nav_hunk("next") end, "Next hunk")
        m("[h", function() gs.nav_hunk("prev") end, "Prev hunk")
        m("<leader>hs", gs.stage_hunk, "Stage hunk")
        m("<leader>hr", gs.reset_hunk, "Reset hunk")
        m("<leader>hS", gs.stage_buffer, "Stage buffer")
        m("<leader>hp", gs.preview_hunk, "Preview hunk")
        m("<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        m("<leader>hd", gs.diffthis, "Diff this")
        m("<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")
      end,
    },
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = { { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
  },
}
