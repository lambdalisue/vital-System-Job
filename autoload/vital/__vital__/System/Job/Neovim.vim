let s:t_func = type(function('tr'))
let s:newline = has('win32') || has('win64') ? "\r\n" : "\n"


function! s:is_available() abort
  return has('nvim')
endfunction

function! s:start(cmd, ...) abort
  let job = extend({
        \ '__exitcode': v:null,
        \ 'on_stdout': 'pipe',
        \ 'on_stderr': 'pipe',
        \ 'on_exit': v:null,
        \}, a:0 ? a:1 : {}
        \)
  " on_stdout
  if job.on_stdout is# v:null
    unlet job.on_stdout
  elseif job.on_stdout ==# 'pipe'
    let job.stdout = deepcopy(s:channel)
    let job.on_stdout = function('s:_on_receive_ch', [], job)
  endif
  " on_stderr
  if job.on_stderr is# v:null
    unlet job.on_stderr
  elseif job.on_stderr ==# 'pipe'
    let job.stderr = deepcopy(s:channel)
    let job.on_stderr = function('s:_on_receive_ch', [], job)
  endif
  " on_exit
  if type(job.on_exit) == s:t_func
    let job.__on_exit = job.on_exit
  endif
  let job.on_exit = function('s:_on_exit', [], job)
  " start job
  let job.__job = jobstart(a:cmd, job)
  return extend(job, s:job)
endfunction


" Callback -----------------------------------------------------------------
function! s:_on_receive_ch(job_id, data, event) abort dict
  let channel = self[a:event]
  if empty(channel.__data)
    let channel.__data = ['']
  endif
  let channel.__data[-1] .= a:data[0]
  call extend(channel.__data, a:data[1:])
endfunction

function! s:_on_exit(job_id, exitcode, event) abort dict
  let self.__exitcode = a:exitcode
  if has_key(self, '__on_exit')
    call self.__on_exit(a:job_id, a:exitcode, a:event)
  endif
endfunction


" Channel ------------------------------------------------------------------
let s:channel = {'__data': []}

function! s:channel.read() abort
  if len(self.__data) == 0
    return v:null
  endif
  return remove(self.__data, 0, -1)
endfunction


" Job ----------------------------------------------------------------------
let s:job = {}

function! s:job.id() abort
  return self.__job
endfunction

function! s:job.status() abort
  try
    call jobpid(self.__job)
    return 'run'
  catch /^Vim\%((\a\+)\)\=:E900/
    return 'dead'
  endtry
endfunction

function! s:job.send(data) abort
  return jobsend(self.__job, a:data)
endfunction

function! s:job.stop() abort
  try
    call jobstop(self.__job)
  catch /^Vim\%((\a\+)\)\=:E900/
    " NOTE:
    " Vim does not raise exception even the job has already closed so fail
    " silently for 'E900: Invalid job id' exception
  endtry
endfunction

function! s:job.wait(...) abort
  let timeout = get(a:000, 0, v:null)
  if timeout is# v:null
    return jobwait([self.__job])[0]
  else
    return jobwait([self.__job], timeout)[0]
  endif
endfunction
