set formatoptions-=cro " vypnuti komentaru na dalsich radkach kdyz dam enter
nnoremap <buffer><leader>p :call CDebugPrint()<CR>
xnoremap <buffer><leader>p :call CDebugPrint()<CR>

function! CDebugPrint() range
  let selector = input('Selector: ')
  let pattern = '\v^( *)(.*)$'
  let sub = '\1printf("\2 = %' .. selector .. '\\n", (\2));'
  if selector == ''
    return
  elseif selector == 'p'
    let sub = '\1printf("\2 = %' .. selector .. '\\n", ((void*)\2));'
  endif
  exec printf('silent!%d,%ds/%s/%s/', a:firstline, a:lastline, pattern, sub)
endfunction
