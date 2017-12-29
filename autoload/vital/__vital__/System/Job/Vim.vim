let s:newline = has('win32') || has('win64') ? "\r\n" : "\n"

function! s:is_available() abort
  return !has('nvim') && has('patch-8.0.0027')
endfunction

function! s:start(args, options) abort
  let job = extend(copy(s:job), a:options)
  let job_options = {
        \ 'mode': 'raw',
        \ 'timeout': 0,
        \}
  if has_key(job, 'on_stdout')
    let job_options.out_cb = get(job, 'stdout_mode', 'nl') ==# 'nl'
          \ ? function('s:_out_cb_nl', [job])
          \ : function('s:_out_cb_raw', [job])
  else
    let job_options.out_io = 'null'
  endif
  if has_key(job, 'on_stderr')
    let job_options.err_cb = get(job, 'stderr_mode', 'nl') ==# 'nl'
          \ ? function('s:_err_cb_nl', [job])
          \ : function('s:_err_cb_raw', [job])
  else
    let job_options.err_io = 'null'
  endif
  if has_key(job, 'on_stdout') || has_key(job, 'on_stderr')
    let job_options.close_cb = function('s:_close_cb', [job])
  endif
  if has_key(job, 'on_exit')
    let job_options.exit_cb = function('s:_exit_cb', [job])
  endif
  let job.__job = job_start(a:args, job_options)
  let job.args = a:args
  return job
endfunction

function! s:_out_cb_raw(job, channel, msg) abort
  call a:job.on_stdout(split(a:msg, "\n", 1))
endfunction

function! s:_err_cb_raw(job, channel, msg) abort
  call a:job.on_stderr(split(a:msg, "\n", 1))
endfunction

function! s:_out_cb_nl(job, channel, msg) abort
  call a:job.on_stdout(split(a:msg, s:newline, 1))
endfunction

function! s:_err_cb_nl(job, channel, msg) abort
  call a:job.on_stderr(split(a:msg, s:newline, 1))
endfunction

function! s:_close_cb(job, channel) abort
  if has_key(a:job, 'on_stdout')
    let options = {'part': 'out'}
    let l:Out_cb = get(a:job, 'stdout_mode', 'nl') ==# 'nl'
          \ ? function('s:_out_cb_nl')
          \ : function('s:_out_cb_raw')
    while ch_status(a:channel, options) ==# 'buffered'
      call Out_cb(a:job, a:channel, ch_readraw(a:channel, options))
    endwhile
  endif
  if has_key(a:job, 'on_stderr')
    let options = {'part': 'err'}
    let l:Err_cb = get(a:job, 'stderr_mode', 'nl') ==# 'nl'
          \ ? function('s:_err_cb_nl')
          \ : function('s:_err_cb_raw')
    while ch_status(a:channel, options) ==# 'buffered'
      call Err_cb(a:job, a:channel, ch_readraw(a:channel, options))
    endwhile
  endif
endfunction

function! s:_exit_cb(job, _, exitval) abort
  call a:job.on_exit(a:exitval)
endfunction


" Instance -------------------------------------------------------------------
function! s:_job_id() abort dict
  return str2nr(matchstr(string(self.__job), '^process \zs\d\+\ze'))
endfunction

" NOTE:
" On Unix a non-existing command results in "dead" instead
" So returns "dead" instead of "fail" even in non Unix.
function! s:_job_status() abort dict
  let status = job_status(self.__job)
  return status ==# 'fail' ? 'dead' : status
endfunction

" NOTE:
" A Null character (\0) is used as a terminator of a string in Vim.
" Neovim can send \0 by using \n splitted list but in Vim.
" So replace all \n in \n splitted list to ''
function! s:_job_send(data) abort dict
  let data = type(a:data) == v:t_list
        \ ? join(map(a:data, 'substitute(v:val, "\n", '''', ''g'')'), "\n")
        \ : a:data
  if has('win32') || has('win64')
    let data = substitute(data, "\n", "\r\n", 'g')
  endif
  return ch_sendraw(self.__job, data)
endfunction

function! s:_job_stop() abort dict
  return job_stop(self.__job)
endfunction

function! s:_job_wait(...) abort dict
  let timeout = a:0 ? a:1 : v:null
  let timeout = timeout is# v:null ? v:null : timeout / 1000.0
  let start_time = reltime()
  try
    while timeout is# v:null || timeout > reltimefloat(reltime(start_time))
      let status = self.status()
      if status ==# 'fail'
        return -3
      elseif status ==# 'dead'
        let info = job_info(self.__job)
        return info.exitval
      endif
      sleep 1m
    endwhile
  catch /^Vim:Interrupt$/
    call self.stop()
    return 1
  endtry
  return -1
endfunction

" To make debug easier, use funcref instead.
let s:job = {
      \ 'id': function('s:_job_id'),
      \ 'status': function('s:_job_status'),
      \ 'send': function('s:_job_send'),
      \ 'stop': function('s:_job_stop'),
      \ 'wait': function('s:_job_wait'),
      \}
