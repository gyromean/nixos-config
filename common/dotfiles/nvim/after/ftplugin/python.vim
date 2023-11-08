set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
nnoremap <buffer><leader>d :s/\v^( *)(.*)$/\1print(f'{\2 = }')<CR>:noh<CR>
xnoremap <buffer><leader>d :s/\v^( *)(.*)$/\1print(f'{\2 = }')<CR>:noh<CR>
