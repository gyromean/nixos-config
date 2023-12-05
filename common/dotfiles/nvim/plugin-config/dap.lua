local dap = require('dap')

dap.adapters.codelldb = {
  type = 'server',
  host = '127.0.0.1',
  port = 13000,
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
