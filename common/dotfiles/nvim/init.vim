" ----- COLORSCHEME -----
let g:airline_powerline_fonts = 1
let g:nord_italic = 1
let g:nord_italic_comments = 1 " bacha, oba tyhle italicy musi byt jeste pred zavolanim `colorscheme nord`
colorscheme nord
" nastavit highlight na stejnou barvu jako Search (barvy muzu zobrazit pres `:hi`)
hi! link TelescopeMatching Search
hi! link TelescopePreviewLine Search
hi String ctermfg=14 guifg=#8fbcbb
hi Comment guifg=#677591

" ----- SETS -----
set nu rnu
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set ignorecase " musi byt, aby smartcase fungoval
set smartcase " search je case-insensitive az do momentu, kdy dam neco velkejma
set clipboard=unnamedplus " nastavi clipboard na systemovej clipboard
set gdefault " V substitute se dava defaultne g (replace vsude)
set breakindent " text wrap zacina na stejnym indentation levelu
set splitright " novy okna (treba pres vsplit) se oteviraji vpravo (misto defaultne nahore)
set splitbelow " novy okna se oteviraji dole (misto defaultne nahore)
set tildeop " ted kdyz se da ~ aby se menil case pisma, tak to jeste potrebuje motion (nemeni to individualni charakter)
set scrolloff=8 " pri scrollovani bude nahore a dole vzdycky aspon 8 radek (pokud teda nejsem uplne na zacatku nebo na konci souboru)
set undofile " bude existovat perzistentni historie zmen, ty pak muzu pouzivat jak z vimu tak z undo tree
set noswapfile " nebude se zakladat a pouzivat swap file
set updatetime=100 " mimo jine se bude vim-gitgutter updatovat kazdych 100 ms
set signcolumn=number " signs (z vim-gitgutter nebo lsp) se budou ukazovat ve sloupecku cisel misto tech cisel
set noshowmode " nebude dola ukazovat v jakym jsem modu, protoze to stejne vidim v airline (diky tomu muzu pouzivat `print` z lua v insert modu a bude to vide)
set termguicolors

" ----- REBINDS -----
let mapleader = " "
" save a close
nnoremap <C-w> :x<CR>
" save
nnoremap <C-s> :w<CR>
" jednorazove vypne highlight ze search commandu
nnoremap <leader>n :noh<CR>
" paste v insert modu pres ctrl+v; `:h i_CTRL-R_CTRL-O`, ten <C-p> vypne to automaticky vim formatovani ktery to vetsinou posere, viz komentar pod dotazem zde https://vi.stackexchange.com/questions/12049/how-to-set-up-crtl-v-map-that-works-in-insert-mode (v tom komentu je to <C-r><C-p>, ale lepsi je <C-r><C-o> jak pouzivam ja)
inoremap <C-v> <C-r><C-o>+
" na wincmd, takze treba `space+w+s` splitne okno horizontalne, `space+w+v` splitne okno vertikalne atd.
nnoremap <leader>w <C-w>
nnoremap <C-h> :wincmd h<CR>
nnoremap <C-j> :wincmd j<CR>
nnoremap <C-k> :wincmd k<CR>
nnoremap <C-l> :wincmd l<CR>
" v visual modu kdyz neco selectu a prepisu to pres paste, tak se to co prepisuju zkopiruje do clipboardu - tohle zpusobi, ze v clipboardu zustane puvodni obsah
xnoremap <leader>p "_dP
" mazani aniz by se prepsal obsah clipboardu
noremap <leader>d "_d
" otevre Undotree, do nej preskocim jako do jinyho okna, takze <C-h>
nnoremap <leader>u :UndotreeToggle<CR>
nnoremap <C-f> :Telescope find_files<CR>
nnoremap <C-g> :Telescope live_grep<CR>
" easymotion prebindovat na [ a ]
nnoremap [[ <Plug>(easymotion-F)
nnoremap ]] <Plug>(easymotion-f)
xnoremap [[ <Plug>(easymotion-F)
xnoremap ]] <Plug>(easymotion-f)
" easymotion prebindovat na [ a ] i v pythonu, protoze u nej se to samo prebinduje
autocmd FileType python nnoremap <buffer> [[ <Plug>(easymotion-F)
autocmd FileType python nnoremap <buffer> ]] <Plug>(easymotion-f)
autocmd FileType python xnoremap <buffer> [[ <Plug>(easymotion-F)
autocmd FileType python xnoremap <buffer> ]] <Plug>(easymotion-f)
" navigace uvnitr snippetu z autocompletu
inoremap <C-h> <cmd>lua require'luasnip'.jump(-1)<CR>
snoremap <C-h> <cmd>lua require'luasnip'.jump(-1)<CR>
inoremap <C-l> <cmd>lua require'luasnip'.jump(1)<CR>
snoremap <C-l> <cmd>lua require'luasnip'.jump(1)<CR>
inoremap <C-y> <cmd>lua require'luasnip'.jump(1)<CR>
snoremap <C-y> <cmd>lua require'luasnip'.jump(1)<CR>
" vlozeni slozenych zavorek
inoremap <C-p> <end><CR>{<CR>}<up><end><CR>
" search results jsou vzdy uprostred obrazovky (ted to funguje jen smerem dopredu, <C-N> je for some reason MALE n)
nnoremap <C-N> nzz

" ----- PLUGIN SETTINGS -----
luafile /home/pavel/.config/nixos-config/common/dotfiles/nvim/plugin-config/commentary.lua
luafile /home/pavel/.config/nixos-config/common/dotfiles/nvim/plugin-config/easymotion.lua
luafile /home/pavel/.config/nixos-config/common/dotfiles/nvim/plugin-config/treesitter.lua
luafile /home/pavel/.config/nixos-config/common/dotfiles/nvim/plugin-config/lsp-zero.lua
luafile /home/pavel/.config/nixos-config/common/dotfiles/nvim/plugin-config/cmp.lua
luafile /home/pavel/.config/nixos-config/common/dotfiles/nvim/plugin-config/lspsaga.lua
luafile /home/pavel/.config/nixos-config/common/dotfiles/nvim/plugin-config/indent-blankline.lua
luafile /home/pavel/.config/nixos-config/common/dotfiles/nvim/plugin-config/treesitter-context.lua
luafile /home/pavel/.config/nixos-config/common/dotfiles/nvim/plugin-config/telescope.lua