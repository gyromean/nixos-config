vim.keymap.set({"n", "x"}, "<leader>p", [[:s/\v^(\s*)(.*)/\1fmt.Println("\2 =", \2)<CR>:noh<CR>]], { buffer = true } );
