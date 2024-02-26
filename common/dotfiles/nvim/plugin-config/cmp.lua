local cmp = require('cmp')

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
    end,
  },
  sources = cmp.config.sources({
    { name = 'path' },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }),
  mapping = {
    ['<CR>'] = cmp.config.disable,
    ['<C-P>'] = cmp.config.disable, -- for some reason to musi byt velky P
    ['<C-d>'] = cmp.mapping(function(fallback) fallback() end, {"s"}), -- disablovat <C-d> v select modu, idk jestli je to dobre
    ['<Tab>'] = cmp.mapping(function(fallback) fallback() end, {"s", "i"}), -- disablovat <C-d> v select modu, idk jestli je to dobre

    ['<C-j>'] = cmp.mapping.select_next_item(),
    ['<C-k>'] = cmp.mapping.select_prev_item(),
    ['<C-y>'] = cmp.mapping.confirm(),
  },
})
