set formatoptions-=cro " vypnuti komentaru na dalsich radkach kdyz dam enter
nnoremap <buffer><leader>p :s/\v^( *)(.*)$/\1vim.print('\2 = ' .. vim.inspect(\2))<CR>:noh<CR>
xnoremap <buffer><leader>p :s/\v^( *)(.*)$/\1vim.print('\2 = ' .. vim.inspect(\2))<CR>:noh<CR>
