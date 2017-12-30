let s:t_string = type('')
let s:t_list = type([])

function! s:_vital_loaded(V) abort
  if has('nvim')
    let s:Job = a:V.import('System.Job.Neovim')
  else
    let s:Job = a:V.import('System.Job.Vim')
  endif
endfunction

function! s:_vital_depends() abort
  return [
        \ 'System.Job.Vim',
        \ 'System.Job.Neovim',
        \]
endfunction


" Note:
" Vim does not raise E902 on Unix system even the prog is not found so use a
" custom exception instead to make the method compatible.
function! s:_validate_args(args) abort
  if type(a:args) != s:t_string && type(a:args) != s:t_list
    throw 'vital: System.Job: Argument requires to be a String or List instance.'
  endif
  if type(a:args) == s:t_list
    if len(a:args) == 0
      throw 'vital: System.Job: Argument vector must have at least one item.'
    endif
    let prog = a:args[0]
    if !executable(prog)
      throw printf('vital: System.Job: "%s" is not an executable', prog)
    endif
  endif
endfunction

function! s:is_available() abort
  return s:Job.is_available()
endfunction

function! s:start(args, ...) abort
  call s:_validate_args(a:args)
  return s:Job.start(a:args, a:0 ? a:1 : {})
endfunction
