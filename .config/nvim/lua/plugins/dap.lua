-- lua/plugins/dap.lua - debugging core (DAP). Language adapters are contributed
-- by stack modules in lua/lsp/langs/ (e.g. python.lua adds nvim-dap-python).
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
    },
    keys = {
      { "<leader>d", "", desc = "+debug" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Eval expression" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      -- Open/close the UI automatically with the debug session.
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
      -- Gutter signs
      vim.fn.sign_define("DapBreakpoint", { text = " ", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = " ", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = " ", texthl = "DiagnosticWarn", linehl = "Visual" })
    end,
  },
}
