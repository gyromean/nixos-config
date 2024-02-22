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

require("dapui").setup()

require("nvim-dap-virtual-text").setup()
