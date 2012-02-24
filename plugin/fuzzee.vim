" fuzzee.vim - Fuzzy expansions for :e and :E
" Author:        Matt Sacks <matt.s.sacks@gmail.com>
" Version:       1.0
" Last Modified: 02/20/12

if exists('g:loaded_fuzzee') || v:version < 700
  finish
endif
let g:loaded_fuzzee = 1

" utility {{{1
function! s:gsub(str,pat,rep) abort
  return substitute(a:str,'\v\C'.a:pat,a:rep,'g')
endfunction

" sort by shortest pathname first
function! s:sortfile(f1, f2)
  return a:f1 == a:f2 ? 0 : len(a:f1) > len(a:f2) ? 1 : -1
endfunction

" return the sorted list with either the tail of the relative path 
" or the full pathname
function! s:sortlist(ls, tail)
  if a:tail
    return sort(map(copy(split(a:ls, "\n")), 'fnamemodify(v:val, ":t")'), 's:sortfile')
  else
    return sort(split(a:ls, "\n"), 's:sortfile')
  endif
endfunction

" remove the trailing '/' and prepended './' to the cwd path
function! s:filterglob(ls, cwd)
    let ls = substitute(a:ls, a:cwd.'/', '', 'g')
    return substitute(ls, '\.\/', '', 'g')
endfunction
" END utility }}}1

" fuzzyglob {{{1
function! s:fuzzglob(arg,L,P)
  let s:head = ''
  if &ft == 'netrw' && expand('%') =~ '^$'
    let dir   = fnameescape(b:netrw_curdir)
    let updir = fnameescape(fnamemodify(b:netrw_curdir, ':h'))
  else
    let dir   = fnameescape(expand('%'))
    let updir = fnameescape(expand('%:h'))
  endif
  let cwd = fnameescape(getcwd())

  " before fuzzy-expansion {{{2
  if a:arg =~ '^\s*$'
    if &ft == 'netrw'
      if dir =~ '^$'
        return s:sortlist(globpath('/', '*'), 1)
      else
        return s:sortlist(globpath(dir, '*'), 1)
      endif
    elseif dir =~ '^$'
      return s:sortlist(globpath(cwd, '*'), 1)
    else
      return s:sortlist(globpath(updir, '*'), 1)
    endif
  endif

  let f = a:arg

  if a:arg =~ '^\/$'
    return s:sortlist(globpath('/', '*'), 0)
  endif

  if a:arg =~ '^\.\/'
    let s:head = '.'
  endif

  " expand the full path if given a relative '../' argument and prepend
  " to the :F argument
  if a:arg =~ '^\.\.\/'
    let dots = matchlist(a:arg, '\(\.\.\/\)\+')[0]
    let path = matchlist(a:arg, '\%(\.\.\/\)\+\(.*\)$')[1]
    if &ft == 'netrw'
      let f = fnamemodify(dir.'/'.dots, ':p')
    else
      let f = fnamemodify(updir.'/'.dots, ':p')
    endif
    let f = f . path
  endif
  " END fuzzy-expansion }}}2
  
  " fuzzy-glob from Tim Pope's utilities
  let f    = s:gsub(s:gsub(f,'[^/.]','[&]*'),'%(/|^)\.@!|\.','&*')

  if a:arg =~ '^\*\/'
    let f  = substitute(f, '^\*[\*\]\*', '**', '')
  endif
  let f    = s:gsub(f, '\*[\*\]\*', '**/*')
  let f    = substitute(f, '\*\[[~`]\]', '$HOME', '')
  let tail = fnamemodify(f, ':t')

  " its globbering time {{{2
  if f == tail && &ft != 'netrw'
    let ls = globpath(updir, f)
  elseif &ft == 'netrw'
    if s:head !~ '^$'
      let ls = globpath(cwd, tail)
    elseif f =~ '^\/' && f !~ '\/*$'
      let ls = globpath('/', tail)
    elseif f =~# '^$HOME'
      let ls = s:gsub(globpath(f, ''), '/$', '')
    elseif dir =~ '^\/$'
      let ls = globpath('/', f)
    elseif a:arg =~ '^*\/'
      let ls = globpath(cwd, f)
      let ls = s:filterglob(ls, cwd)
    elseif a:arg =~  '^*'
      let ls = globpath(dir, f)
      let ls = s:filterglob(ls, cwd)
    else
      let ls = globpath(dir, f)
    endif
  else
    if s:head !~ '^$'
      let f  = substitute(f, '^\.\*', '\.', '')
      let ls = globpath(cwd, f)
    elseif a:arg =~ '^\*\/'
      let ls = globpath(cwd, f)
    elseif a:arg =~  '^\*'
      let s:head = updir
      let ls = globpath(updir, f)
    else
      let ls = globpath(updir, f)
    endif
    let ls = s:filterglob(ls, cwd)
  endif

  " return the globbed files {{{2
  if len(ls) == 0 && tail !~ '\.'
    " defer globbing if not necessary
    if s:head !~ '^$'
      echomsg 'not found'
      return ''
    elseif len(glob(f)) == 0
      echomsg 'not found'
      return ''
    endif
    return s:sortlist(glob(f), 0)
  elseif len(ls) == 0
    return s:sortlist(glob(f), 0)
  else
    if &ft == 'netrw' && f == tail && s:head =~ '^$'
      let s:head = fnamemodify(split(ls, "\n")[0], ':h')
    elseif f == tail && &ft != 'netrw' && s:head =~ '^$'
      let s:head = updir
    endif
    if f == tail
      return s:sortlist(ls, 1)
    else
      return s:sortlist(ls, 0)
    endif
  endif
endfunction
" END fuzzyglob }}}1

" the F command {{{1
function! s:F(cmd, ...)
  let cmds  = {'E': 'edit', 'S': 'split', 'V': 'vsplit', 'T': 'tabedit',
              \'L': 'lcd', 'C': 'cd'}
  let cmd   = cmds[a:cmd]
  if &ft == 'netrw' && expand('%') =~ '^$'
    let dir   = substitute(fnameescape(b:netrw_curdir), '\(.\)/$', '\1', '')
    let updir = substitute(fnameescape(fnamemodify(b:netrw_curdir, ':h')), '\(.\)/$', '\1', '')
  else
    let dir   = substitute(fnameescape(expand('%')), '\(.\)/$', '\1', '')
    let updir = substitute(fnameescape(expand('%:h')), '\(.\)/$', '\1', '')
  endif
  let cwd   = substitute(fnameescape(getcwd()), '\(.\)/$', '\1', '')

  if a:0 == 0
    if &ft == 'netrw'
      execute 'silent! ' cmd dir
    else
      execute 'silent! ' cmd updir
    endif
    return ''
  endif

  if a:1 =~ '^\.$'
    execute 'silent! '.cmd cwd
    return ''
  endif

  let f = s:fuzzglob(a:1, '', '')
  " remove the prepended '/' if globbed from the root
  if (s:head =~ '^\.' && f[0][0] == '/') || s:head =~ '^\/$'
    let s:head = ''
  endif
  if len(f) == 0
    return ''
  elseif s:head !~ '^$'
    execute 'silent! '.cmd fnameescape(s:head.'/'.f[0])
  else
    execute 'silent! '.cmd fnameescape(f[0])
  endif
  if &ft != 'netrw'
    execute 'silent! lcd' fnameescape(getcwd())
  endif
endfunction
" END the F command }}}1

" fuzzee-buffer {{{1
function! s:buffglob(arg,L,P)
  let buffers = []
  for b in range(1, bufnr('$'))
    if bufexists(b) && buflisted(b) == 1
      call add(buffers, bufname(b))
    endif
  endfor
  if a:arg =~ '^$'
    return buffers
  endif

  let b = s:gsub(s:gsub(a:arg,'[^/.\>]','[&].*'),'%(/|^)\.@!|\.','&')
  let b = s:gsub(b, '\*\[ \]\*', '*')

  return filter(buffers, 'v:val =~ b')
endfunction

function! s:FB(...)
  if a:0 == 0
    execute 'silent! b' bufname('#')
    return ''
  endif

  let f = s:buffglob(a:1, '', '')
  if len(f) == 0
    echomsg 'no buffers found'
    return ''
  endif
  let s = ''

  if &switchbuf !~ '^$'
    for i in range(1, tabpagenr('$'))
      if index(tabpagebuflist(i), bufnr(f[0])) != -1
        let s = 's'
        break
      endif
    endfor
  endif
  execute 'silent '.s.'b' f[0]
endfunction
" END fuzzee-buffer }}}1

command! -nargs=? -bar -complete=customlist,s:fuzzglob F  :execute s:F('E', <f-args>)
command! -nargs=? -bar -complete=customlist,s:fuzzglob FS :execute s:F('S', <f-args>)
command! -nargs=? -bar -complete=customlist,s:fuzzglob FV :execute s:F('V', <f-args>)
command! -nargs=? -bar -complete=customlist,s:fuzzglob FT :execute s:F('T', <f-args>)
command! -nargs=? -bar -complete=customlist,s:fuzzglob FL :execute s:F('L', <f-args>)
command! -nargs=? -bar -complete=customlist,s:fuzzglob FC :execute s:F('C', <f-args>)
command! -nargs=? -bar -complete=customlist,s:buffglob FB :execute s:FB(<f-args>)
