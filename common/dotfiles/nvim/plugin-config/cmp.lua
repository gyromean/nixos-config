local cmp = require('cmp')
local cmp_select_opts = {behavior = cmp.SelectBehavior.Select}
cmp.setup({
  sources = {
    { name = 'path' },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
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
