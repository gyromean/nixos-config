local ls = require'luasnip'

ls.setup({
  update_events = {'TextChanged', 'TextChangedI'},
  enable_autosnippets = true,
})

require'luasnip.loaders.from_lua'.load({ paths = "/home/pavel/.config/custom/dotfiles/nvim/snippets" })
