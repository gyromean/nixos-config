" disable these functions, as they are specific to using X11
" funkce na autoamticky switchnuti zpatky do viku po zavolani vimtex-view
" if !exists("g:vim_window_id")
"   let g:vim_window_id = system("xdotool getactivewindow")
" endif

" function! s:TexFocusVim() abort
"   sleep 150m
"   silent execute "!xdotool windowfocus " . expand(g:vim_window_id)
"   redraw!
" endfunction

" augroup vimtex_event_focus
"   au!
"   au User VimtexEventView call s:TexFocusVim()
" augroup END

" --------------

nmap <leader>ll <Plug>(vimtex-compile)
nmap <leader>lv <Plug>(vimtex-view)
nmap <leader>li <Plug>(vimtex-info)
nmap <leader>lt <Plug>(vimtex-toc-open)
nmap <leader>lc <Plug>(vimtex-clean)
nmap <leader>lC <Plug>(vimtex-clean-full)

imap <C-]> <Plug>(vimtex-delim-close)

nmap % <Plug>(vimtex-%)
xmap % <Plug>(vimtex-%)

" Text objects:
" commands
xmap ac <plug>(vimtex-ac)
omap ac <plug>(vimtex-ac)
xmap ic <plug>(vimtex-ic)
omap ic <plug>(vimtex-ic)
" delimiters
xmap ad <plug>(vimtex-ad)
omap ad <plug>(vimtex-ad)
xmap id <plug>(vimtex-id)
omap id <plug>(vimtex-id)
" environments
xmap ae <plug>(vimtex-ae)
omap ae <plug>(vimtex-ae)
xmap ie <plug>(vimtex-ie)
omap ie <plug>(vimtex-ie)
" math
xmap a$ <plug>(vimtex-a$)
omap a$ <plug>(vimtex-a$)
xmap i$ <plug>(vimtex-i$)
omap i$ <plug>(vimtex-i$)
" sections
xmap aP <plug>(vimtex-aP)
omap aP <plug>(vimtex-aP)
xmap iP <plug>(vimtex-iP)
omap iP <plug>(vimtex-iP)
" items
xmap am <plug>(vimtex-am)
omap am <plug>(vimtex-am)
xmap im <plug>(vimtex-im)
omap im <plug>(vimtex-im)
