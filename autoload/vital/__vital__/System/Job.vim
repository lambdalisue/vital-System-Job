function! s:_vital_loaded(V) abort
  if has('nvim')
    let s:Job = a:V.import('System.Job.Neovim')
  else
    let s:Job = a:V.import('System.Job.Vim')
  endif
endfunction

function! s:_vital_depends() abort
  return ['System.Job.Vim', 'System.Job.Neovim']
endfunction

function! s:is_available(...) abort
  return call(s:Job.is_available, a:000, s:Job)
endfunction

function! s:start(...) abort
  return call(s:Job.start, a:000, s:Job)
endfunction
