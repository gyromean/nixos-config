set formatoptions-=cro " vypnuti komentaru na dalsich radkach kdyz dam enter
nnoremap <buffer><leader>p :s/\v^( *)(.*)$/\1print('\2 = ', (\2))<CR>:noh<CR>
xnoremap <buffer><leader>p :s/\v^( *)(.*)$/\1print('\2 = ', (\2))<CR>:noh<CR>
