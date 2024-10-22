vim.opt.formatoptions:remove({"c", "r", "o"})
vim.keymap.set({"n", "x"}, "<leader>p", [[:s/\v^( *)(.*)/\1echo "\2 = ${\2}"<CR>:noh<CR>]], { buffer = true } );
