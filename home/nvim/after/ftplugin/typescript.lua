vim.opt.formatoptions:remove({"c", "r", "o"})

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.keymap.set({"n", "x"}, "<leader>p", [[:s/\v^( *)(.*)/\1console.log(`\2 =`, \2)<CR>:noh<CR>]], { buffer = true } );
