" fuzzee.vim - Fuzzy expansions for :e and :E
" Author: Matt Sacks <matt.s.sacks@gmail.com>
" Version: 0.4

if exists('g:loaded_fuzzee') || v:version < 700
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
    return sort(map(copy(split(a:ls, "\n")), 'fnamemodify(v:val, ":t")'), 's:sortfile')
  else
    return sort(split(a:ls, "\n"), 's:sortfile')
  endif
endfunction

function! s:filterglob(ls, cwd)
    let ls = substitute(a:ls, a:cwd.'/', '', 'g')
    return substitute(ls, '\.\/', '', 'g')
endfunction

function! s:fuzzglob(arg,L,P)
  let s:head = ''
  if a:arg =~ '^\s*$'
    if &buftype == 'nofile'
      if expand('%') =~ '^$' " new buffer is blank
        return s:sortlist(globpath('/', '*'), 1)
      else
        return s:sortlist(globpath('%'.'/', '*'), 1)
      endif
    elseif expand('%') =~ '^$'
      return s:sortlist(globpath(getcwd(), '*'), 1)
    else 
      return s:sortlist(globpath('%:h', '*'), 1)
    endif
  endif

  let f = a:arg

  if a:arg =~ '^\/$'
    return s:sortlist(globpath('/', '*'), 0)
  endif

  if a:arg =~ '^\.\/'
    let s:head = '.'
  endif

  let dir   = escape(expand('%'), ' ')
  let updir = escape(expand('%:h'), ' ')
  let cwd   = escape(getcwd(), ' ')

  if a:arg =~ '^\.\.\/'
    let dots = matchlist(a:arg, '^\(\.\.\/\)\+')[0]
    let path = matchlist(a:arg, '^\%(\.\.\/\)\+\(.*\)$')[1]
    if &buftype == 'nofile'
      let f = fnamemodify(dir.'/'.dots, ':p')
    else
      let f = fnamemodify(updir.'/'.dots, ':p')
    endif
    let f = f.path
  endif

  let f    = s:gsub(s:gsub(f,'[^/.]','[&]*'),'%(/|^)\.@!|\.','&*')
  let f    = substitute(f, '\*\[[~`]\]\*', '$HOME', '')
  let f    = substitute(f, '\*[\*\]\*', '\*\*\/\*', 'g') 
  let tail = fnamemodify(f, ':t')
  
  " if completing a directory
  if f == tail && &buftype != 'nofile'
    let ls = globpath(updir, f)
  elseif &buftype == 'nofile'
    if (s:head !~ '^$')
      let ls = globpath(cwd, ' ')
    elseif f =~# '^$HOME'
      let ls = substitute(globpath(f, ''), '\/$', '', 'g')
    elseif dir =~ '^\/$'
      let ls = globpath('/', f)
    elseif a:arg =~ '^*\/'
      let ls = globpath(cwd, f)."\n"
             \.globpath(cwd, fnamemodify(f, ':t'))
      let ls = s:filterglob(ls, cwd)
    elseif a:arg =~  '^*'
      let s:head = dir
      let ls = globpath(dir, f)
      let ls = s:filterglob(ls, cwd)
    else
      let ls = globpath(dir, f)
    endif
  else
    if s:head !~ '^$'
      let f = substitute(f, '^\.\*', '\.', '')
      let ls = globpath(cwd, f)
    elseif a:arg =~ '^\*\/'
      let ls = globpath(cwd, f)."\n"
             \.globpath(cwd, fnamemodify(f, ':t'))
    elseif a:arg =~  '^\*'
      let s:head = updir
      let ls = globpath(updir, f)
    else
      let ls  = globpath(updir, f)
    endif
    let ls = s:filterglob(ls, cwd)
  endif

  if len(ls) == 0 && tail !~ '\.'
    if len(glob(f)) == 0
      echomsg 'not found'
      return ''
    endif
    return s:sortlist(glob(f), 0)
  elseif len(ls) == 0
    return s:sortlist(glob(f), 0)
  else
    if &buftype == 'nofile' && f == tail && s:head =~ '^$'
      let s:head = fnamemodify(split(ls, "\n")[0], ':h')
    elseif f == tail && &buftype != 'nofile' && s:head =~ '^$'
      let s:head = updir
    endif
    if f == tail 
      return s:sortlist(ls, 1)
    else
      return s:sortlist(ls, 0)
    endif
  endif
endfunction

function! s:F(cmd, ...)
  let cmds = {'E': 'edit', 'S': 'split', 'V': 'vsplit', 'T': 'tabedit',
             \'L': 'lcd', 'C': 'cd'}
  let chdir  = ['L', 'C']
  let cmd  = cmds[a:cmd]
  let dir   = substitute(escape(expand('%'), ' '), '\(.\)/$', '\1', '')
  let updir = substitute(escape(expand('%:h'), ' '), '\(.\)/$', '\1', '')
  let cwd   = substitute(escape(getcwd(), ' '), '\(.\)/$', '\1', '')

  if a:0 == 0
    if expand("%") =~# '^$'
      execute 'silent! ' cmd cwd
    elseif &buftype == 'nofile'
      execute 'silent! ' cmd dir
    else
      execute 'silent! ' cmd updir
    endif
    return
  endif

  if a:1 =~ '^\.$'
    execute 'silent! '.cmd cwd
    return
  endif

  let f = s:fuzzglob(a:1, '', '')
  if (s:head =~ '^\.' && f[0][0] == '/') || s:head =~ '^\/$'
    let s:head = ''
  endif
  if len(f) == 0
    return
  elseif s:head !~ '^$'
    execute 'silent! '.cmd escape(s:head.'/'.f[0], ' ')
  else
    execute 'silent! '.cmd escape(f[0], ' ')
  endif
  execute 'silent! lcd' substitute(escape(getcwd(), ' '), '\(.\)/$', '\1', '')
endfunction

command! -nargs=? -complete=customlist,s:fuzzglob F  :execute s:F('E', <f-args>)
command! -nargs=? -complete=customlist,s:fuzzglob FS :execute s:F('S', <f-args>)
command! -nargs=? -complete=customlist,s:fuzzglob FV :execute s:F('V', <f-args>)
command! -nargs=? -complete=customlist,s:fuzzglob FT :execute s:F('T', <f-args>)
command! -nargs=? -complete=customlist,s:fuzzglob FL :execute s:F('L', <f-args>)
command! -nargs=? -complete=customlist,s:fuzzglob FC :execute s:F('C', <f-args>)
