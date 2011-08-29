" fuzzee.vim - Fuzzy expansions for :e and :E
" Author: Matt Sacks <matt.s.sacks@gmail.com>
" Version: 0.1

if exists('g:loaded_fuzzee') || v:version < 700 || &cp
  finish
endif
let g:loaded_fuzzee = 1

function! s:gsub(str,pat,rep) abort
  return substitute(a:str,'\v\C'.a:pat,a:rep,'g')
endfunction

function! s:sortfile(f1, f2)
  return a:f1 == a:f2 ? 0 : len(a:f1) > len(a:f2) ? 1 : -1
endfunction

function! s:sortlist(ls, tail)
  if a:tail
    return sort(map(copy(split(a:ls, '\n')), 'fnamemodify(v:val, ":t")'), 's:sortfile')
  else
    return sort(split(a:ls, '\n'), 's:sortfile')
  endif
endfunction

function! s:fuzzglob(arg,L,P)
  let s:head = ''
  if a:arg =~ '^\s*$'
    if &buftype == 'nofile'
      if expand("%") =~ '^$' " buffer is blank at root
        return s:sortlist(globpath('/', '*'), 1)
      else
        return s:sortlist(globpath("%".'/', "*"), 1)
      endif
    else 
      return s:sortlist(globpath("%:h", "*"), 1)
    endif
  endif

  let f = a:arg

  if a:arg =~ '^\/$'
    return s:sortlist(globpath('/', "*"), 0)
  endif

  if a:arg =~ '^\.\/'
    let s:head = "."
  endif

  if a:arg =~ '^\.\.\/'
    let dots = matchlist(a:arg, '^\(\.\.\/\)\+')[0]
    let path = matchlist(a:arg, '^\%(\.\.\/\)\+\(.*\)$')[1]
    if &buftype == 'nofile'
      let f = fnamemodify(expand("%").'/'.dots, ':p')
    else
      let f = fnamemodify(expand("%:h").'/'.dots, ':p')
    endif
    let f = f.path
  endif

  let f    = s:gsub(s:gsub(f,'[^/.]','[&]*'),'%(/|^)\.@!|\.','&*')
  let f    = substitute(f, '\*\[[~`]\]\*', '$HOME', '')
  let tail = fnamemodify(f, ':t')
  
  " if completing a directory
  if f == tail && &buftype != 'nofile'
    let ls = globpath("%:h", f)
  elseif &buftype == 'nofile'
    if s:head !~ '^$'
      let ls = globpath(getcwd(), f)
    else
      let ls = globpath('%', f)
    endif
  else
    if s:head !~ '^$'
      let f = substitute(f, '^\.\*', '\.', '')
      let ls = globpath(getcwd(), f)
    else
      let ls  = globpath('%:h', f)
    endif
    let ls2 = map(copy(split(ls, "\n")), 'substitute(v:val, "^\.\/", "", "")')
    let ls  = join(ls2, "\n")
  endif

  if len(ls) == 0 && tail !~ '\.'
    if len(glob(f)) == 0
      echomsg "not found"
      return ''
    endif
    return s:sortlist(glob(f), 0)
  elseif len(ls) == 0
    return s:sortlist(glob(f), 0)
  else
    if &buftype == 'nofile' && f == tail
      let s:head = fnamemodify(split(ls, "\n")[0], ':h')
    elseif f == tail && &buftype != 'nofile' && s:head =~ '^$'
      let s:head = expand("%:h")
    endif
    if f == tail
      return s:sortlist(ls, 1)
    else
      return s:sortlist(ls, 0)
    endif
  endif
endfunction

function! s:F(...)
  if a:0 == 0
    if &buftype == 'nofile'
      execute "Explore %"
    else
      execute "Explore %:h"
    endif
    return
  endif

  if a:1 =~ '^\.$'
    return "silent! edit ."
  endif

  let f = s:fuzzglob(a:1, '', '')
  if s:head =~ '^\.' && f[0][0] == '/'
    let s:head = ''
  endif
  if len(f) == 0
    return
  elseif s:head !~ '^$'
    let f[0] = substitute(f[0], '\s', '\\ ' ,'g')
    execute "silent! edit" s:head.'/'.f[0]
  else
    let f[0] = substitute(f[0], '\s', '\\ ' ,'g')
    execute "silent! edit" f[0]
  endif
  execute "silent! lcd" getcwd()
endfunction

command! -nargs=? -complete=customlist,s:fuzzglob F :execute s:F(<f-args>)
