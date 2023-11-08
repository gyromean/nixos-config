set formatoptions-=cro " vypnuti komentaru na dalsich radkach kdyz dam enter
nnoremap <buffer><leader>d :s/\v^( *)(.*)$/\1cerr << "\2 = " << (\2) << endl;<CR>:noh<CR>
xnoremap <buffer><leader>d :s/\v^( *)(.*)$/\1cerr << "\2 = " << (\2) << endl;<CR>:noh<CR>
