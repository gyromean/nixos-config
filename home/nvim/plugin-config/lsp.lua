vim.lsp.config('hls', {
  filetypes = { 'haskell', 'lhaskell', 'cabal' },
})

vim.lsp.enable('pyright')
vim.lsp.enable('nixd')
vim.lsp.enable('clangd')
vim.lsp.enable('lua_ls')
vim.lsp.enable('bashls')
vim.lsp.enable('rust_analyzer')
vim.lsp.enable('ts_ls')
vim.lsp.enable('hls')

-- lspconfig.texlab.setup({})
-- -- lspconfig.ltex.setup({
-- --   settings = {
-- --     ltex = {
-- --       language = "en-US";
-- --     },
-- --   },
-- -- })

vim.diagnostic.config({
  virtual_lines = true,
  -- virtual_text = true,
  underline = true,
  severity_sort = true,
  -- update_in_insert = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '◆',
      [vim.diagnostic.severity.WARN] = '▲',
      [vim.diagnostic.severity.INFO] = '■',
      [vim.diagnostic.severity.HINT] = '■',
    },
  },
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        noremap = true,
        silent = true,
        buffer = bufnr,
        desc = desc,
      })
    end

    map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
    map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
    map('n', 'gt', vim.lsp.buf.type_definition, 'Go to type definition')
  end
})

-- lsp_zero.on_attach(function(client, bufnr)
--   local opts = {buffer = bufnr}

--   vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
--   vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
--   vim.keymap.set('n', 'go', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
--   vim.keymap.set('n', 'gl', '<cmd>Lspsaga lsp_finder<cr>', opts)
--   vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
--   vim.keymap.set('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
--   vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<cr>', opts)
--   vim.keymap.set('n', 'gx', '<cmd>Lspsaga code_action<cr>', opts)
--   vim.keymap.set('n', 'gr', '<cmd>Lspsaga rename<cr>', opts)
--   vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)
--   vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)
--   vim.keymap.set('i', '<C-x>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
-- end)
