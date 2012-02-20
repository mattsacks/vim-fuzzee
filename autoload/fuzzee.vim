" for use with cmap to either navigate to a directory or tab-complete the file
" example: FuzzeeMap ,js app/javascript   call fuzzee#map(',js','app/javascript')
"          :F ,js => :F javascript   :F foo,js => :F javascript/foo.js
function! fuzzee#expand(path)
  let l:fCmd = matchstr(getcmdline(), '^F\w\=\s')
  let l:fArg = matchstr(getcmdline(), '^F\w\=\s\zs.*$')
  let l:path = a:path =~ '\/$' || a:path =~ '\*$' ? a:path : a:path . '/'
  return l:fCmd . (l:fArg =~ '^$' ? l:path : l:path . l:fArg)
endfunction

function! fuzzee#map(map, path, ...)
  exe 'cmap' a:map . " <C-\\>efuzzee#expand('" . a:path . "')<CR>" . nr2char(&wcm)
endfunction
command! -complete=file -nargs=+ FuzzeeMap :call fuzzee#map(<f-args>)
