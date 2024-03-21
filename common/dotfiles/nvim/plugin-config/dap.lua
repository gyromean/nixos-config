local dap = require('dap')

dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "-i", "dap" }
}

dap.configurations.cpp = {
  {
    name = "Launch",
    type = "gdb",
    request = "launch",
    program = function()
      if vim.g.dap_selected_program then
        return vim.g.dap_selected_program
      end
      vim.g.dap_selected_program = vim.fn.input('Executable (without args): ', vim.fn.getcwd() .. '/', 'file')
      return vim.g.dap_selected_program
    end,
    args = function()
      if vim.g.dap_selected_program_args then
        return vim.g.dap_selected_program_args
      end
      vim.g.dap_selected_program_args = vim.fn.input('Args: ')
      return vim.g.dap_selected_program_args
    end,
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = false,
  },
}

dap.configurations.c = dap.configurations.cpp;

require("dapui").setup({
    controls = {
      element = "repl",
      enabled = true,
      icons = {
        disconnect = "",
        pause = "",
        play = "",
        run_last = "",
        step_back = "",
        step_into = "",
        step_out = "",
        step_over = "",
        terminate = ""
      }
    },
    element_mappings = {},
    expand_lines = true,
    floating = {
      border = "single",
      mappings = {
        close = { "q", "<Esc>" }
      }
    },
    force_buffers = true,
    icons = {
      collapsed = "",
      current_frame = "",
      expanded = ""
    },
    layouts = { {
        elements = { {
            id = "scopes",
            size = 0.55
          }, {
            id = "breakpoints",
            size = 0.15
          }, {
            id = "stacks",
            size = 0.15
          }, {
            id = "watches",
            size = 0.15
          } },
        position = "left",
        -- size = 40
        size = 70
      }, {
        elements = { {
            id = "repl",
            size = 0.7
          }, {
            id = "console",
            size = 0.3
          } },
        position = "bottom",
        size = 10
      } },
    mappings = {
      edit = "e",
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "x",
      repl = "r",
      toggle = "t"
    },
    render = {
      indent = 1,
      max_value_lines = 100
    }
  }
)

require("nvim-dap-virtual-text").setup()
