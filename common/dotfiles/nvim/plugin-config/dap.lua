local dap = require('dap')

local port = 13000;

dap.adapters.codelldb = {
  type = 'server',
  port = port,
  executable = {
    command = '/nix/store/mx92n3l9ngv29da5vkznf6xc9mlnhlvx-vscode-extension-vadimcn-vscode-lldb-1.9.2/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb',
    args = {"--port", port},
  }
}

dap.configurations.c = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input('Bruhh xD Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}

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
