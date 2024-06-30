set formatoptions-=cro " vypnuti komentaru na dalsich radkach kdyz dam enter
nnoremap <buffer><leader>p :s/\v^( *)(.*)$/\1cerr << "\2 = " << (\2) << endl;<CR>:noh<CR>
xnoremap <buffer><leader>p :s/\v^( *)(.*)$/\1cerr << "\2 = " << (\2) << endl;<CR>:noh<CR>
