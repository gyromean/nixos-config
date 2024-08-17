local lspconfig = require('lspconfig')

local lsp_zero = require('lsp-zero').preset({
  name = 'recommended',
  set_lsp_keymaps = false
})

lsp_zero.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr}

  vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
  vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
  vim.keymap.set('n', 'go', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
  vim.keymap.set('n', 'gl', '<cmd>Lspsaga lsp_finder<cr>', opts)
  vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
  vim.keymap.set('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
  vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<cr>', opts)
  vim.keymap.set('n', 'gx', '<cmd>Lspsaga code_action<cr>', opts)
  vim.keymap.set('n', 'gr', '<cmd>Lspsaga rename<cr>', opts)
  vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)
  vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)
  vim.keymap.set('i', '<C-x>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
end)

lspconfig.nixd.setup({})
lspconfig.clangd.setup({})
lspconfig.pyright.setup({})
lspconfig.lua_ls.setup({})
lspconfig.bashls.setup({})
lspconfig.texlab.setup({})
lspconfig.ltex.setup({
  settings = {
    ltex = {
      language = "en-US";
    },
  },
})
lspconfig.rust_analyzer.setup({})

lsp_zero.set_sign_icons({ -- musi se volat az po lsp.setup()
  error = '◆',
  warn = '▲',
  hint = '■',
})

vim.diagnostic.config({ virtual_text = true }) -- ukaze inline diagnostics (musi se volat az po setupu lsp-zero)
