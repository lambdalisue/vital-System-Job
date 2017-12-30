" http://vim-jp.org/blog/2016/03/23/take-care-of-patch-1577.html
function! s:is_available() abort
  return has('nvim') && has('patch-7.4.1646')
endfunction

function! s:start(args, options) abort
  let job = extend(copy(s:job), a:options)
  let job_options = {}
  if has_key(job, 'on_stdout')
    let job_options.on_stdout = function('s:_on_stdout', [job])
  endif
  if has_key(job, 'on_stderr')
    let job_options.on_stderr = function('s:_on_stderr', [job])
  endif
  if has_key(job, 'on_exit')
    let job_options.on_exit = function('s:_on_exit', [job])
  endif
  let job.__job = jobstart(a:args, job_options)
  let job.args = a:args
  return job
endfunction

function! s:_on_stdout(job, job_id, data, event) abort
  call a:job.on_stdout(a:data)
endfunction

function! s:_on_stderr(job, job_id, data, event) abort
  call a:job.on_stderr(a:data)
endfunction

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

" To make debug easier, use funcref instead.
let s:job = {
      \ 'id': function('s:_job_id'),
      \ 'status': function('s:_job_status'),
      \ 'send': function('s:_job_send'),
      \ 'stop': function('s:_job_stop'),
      \ 'wait': function('s:_job_wait'),
      \}
