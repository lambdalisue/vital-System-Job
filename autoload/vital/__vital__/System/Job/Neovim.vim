let s:is_windows = has('win32') || has('win64')

" http://vim-jp.org/blog/2016/03/23/take-care-of-patch-1577.html
function! s:is_available() abort
  return has('nvim') && has('patch-7.4.1646')
endfunction

function! s:start(args, options) abort
  let job = extend(copy(s:job), a:options)
  let job_options = {}
  if has_key(job, 'on_stdout')
    let job_options.on_stdout = get(job, 'stdout_mode', 'nl') ==# 'nl'
          \ ? function('s:_on_stdout_nl', [job])
          \ : function('s:_on_stdout_raw', [job])
  endif
  if has_key(job, 'on_stderr')
    let job_options.on_stderr = get(job, 'stderr_mode', 'nl') ==# 'nl'
          \ ? function('s:_on_stderr_nl', [job])
          \ : function('s:_on_stderr_raw', [job])
  endif
  if has_key(job, 'on_exit')
    let job_options.on_exit = function('s:_on_exit', [job])
  endif
  let job.__job = jobstart(a:args, job_options)
  let job.args = a:args
  return job
endfunction

function! s:_on_stdout_raw(job, job_id, data, event) abort
  call a:job.on_stdout(a:data)
endfunction

function! s:_on_stderr_raw(job, job_id, data, event) abort
  call a:job.on_stderr(a:data)
endfunction

if s:is_windows
  function! s:_on_stdout_nl(job, job_id, data, event) abort
    let data = map(copy(a:data), 'v:val[-1:] ==# "\r" ? v:val[:-2] : v:val')
    call a:job.on_stdout(data)
  endfunction

  function! s:_on_stderr_nl(job, job_id, data, event) abort
    let data = map(copy(a:data), 'v:val[-1:] ==# "\r" ? v:val[:-2] : v:val')
    call a:job.on_stderr(data)
  endfunction
else
  function! s:_on_stdout_nl(job, job_id, data, event) abort
    call a:job.on_stdout(a:data)
  endfunction

  function! s:_on_stderr_nl(job, job_id, data, event) abort
    call a:job.on_stderr(a:data)
  endfunction
endif

function! s:_on_exit(job, job_id, data, event) abort
  call a:job.on_exit(a:data)
endfunction

" Instance -------------------------------------------------------------------
function! s:_job_id() abort dict
  return self.__job
endfunction

function! s:_job_status() abort dict
  try
    call jobpid(self.__job)
    return 'run'
  catch /^Vim\%((\a\+)\)\=:E900/
    return 'dead'
  endtry
endfunction

function! s:_job_send(data) abort dict
  return jobsend(self.__job, a:data)
endfunction

function! s:_job_stop() abort dict
  try
    call jobstop(self.__job)
  catch /^Vim\%((\a\+)\)\=:E900/
    " NOTE:
    " Vim does not raise exception even the job has already closed so fail
    " silently for 'E900: Invalid job id' exception
  endtry
endfunction

function! s:_job_wait(...) abort dict
  let timeout = a:0 ? a:1 : v:null
  if timeout is# v:null
    return jobwait([self.__job])[0]
  else
    return jobwait([self.__job], timeout)[0]
  endif
endfunction

let s:job = {
      \ 'id': function('s:_job_id'),
      \ 'status': function('s:_job_status'),
      \ 'send': function('s:_job_send'),
      \ 'stop': function('s:_job_stop'),
      \ 'wait': function('s:_job_wait'),
      \}
