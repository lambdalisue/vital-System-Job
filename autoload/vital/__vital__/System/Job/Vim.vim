let s:t_func = type(function('tr'))
let s:t_list = type([])
let s:newline = has('win32') || has('win64') ? "\r\n" : "\n"
let s:STDOUT = {'part': 'out'}
let s:STDERR = {'part': 'err'}


function! s:is_available() abort
  return has('patch-8.0.0105') && !has('nvim')
endfunction

function! s:start(cmd, ...) abort
  let job = extend({
        \ 'on_stdout': 'pipe',
        \ 'on_stderr': 'pipe',
        \ 'on_exit': v:null,
        \}, a:0 ? a:1 : {}
        \)
  let job_options = {
        \ 'mode': 'raw',
        \ 'close_cb': function('s:_on_close', [], job),
        \}
  " on_stdout
  if job.on_stdout ==# 'pipe'
    let job.stdout = extend(deepcopy(s:channel), {
        \ '__job': job,
        \ '__options': s:STDOUT,
        \ '__buffered': [],
        \})
  elseif type(job.on_stdout) == s:t_func
    let job_options.out_cb = function('s:_on_receive_cb', ['stdout'], job)
  endif
  " on_stderr
  if job.on_stderr ==# 'pipe'
    let job.stderr = extend(deepcopy(s:channel), {
        \ '__job': job,
        \ '__options': s:STDERR,
        \ '__buffered': [],
        \})
  elseif type(job.on_stderr) == s:t_func
    let job_options.err_cb = function('s:_on_receive_cb', ['stderr'], job)
  endif
  " on_exit
  if type(job.on_exit) == s:t_func
    let job_options.exit_cb = function('s:_on_exit', [], job)
  endif
  " start job
  let job.__job = job_start(a:cmd, job_options)
  let job.__channel = job_getchannel(job.__job)
  return extend(job, s:job)
endfunction


" Callback -----------------------------------------------------------------
function! s:_on_receive_cb(event, channel, msg) abort dict
  let data = split(a:msg, s:newline, 1)
  call self['on_' . a:event](self.__job, data, a:event)
endfunction

function! s:_on_close(channel) abort dict
  if ch_status(a:channel, s:STDOUT) ==# 'buffered'
    let data = split(
          \ ch_readraw(a:channel, extend({'timeout': 0}, s:STDOUT)),
          \ s:newline, 1
          \)
    if self.on_stdout ==# 'pipe'
      call extend(self.stdout.__buffered, data)
    elseif type(self.on_stdout) == s:t_func
      call self.on_stdout(self.__job, data, 'stdout')
    endif
  endif
  if ch_status(a:channel, s:STDERR) ==# 'buffered'
    let data = split(
          \ ch_readraw(a:channel, extend({'timeout': 0}, s:STDERR)),
          \ s:newline, 1
          \)
    if self.on_stderr ==# 'pipe'
      call extend(self.stderr.__buffered, data)
    elseif type(self.on_stderr) == s:t_func
      call self.on_stderr(self.__job, data, 'stderr')
    endif
  endif
endfunction

function! s:_on_exit(channel, exitcode) abort dict
  call self.on_exit(self.__job, a:exitcode, 'exit')
endfunction


" Channel ------------------------------------------------------------------
let s:channel = {}

function! s:channel.read() abort
  let channel = self.__job.__channel
  let options = self.__options
  let buffered = self.__buffered
  if !empty(buffered)
    return remove(buffered, 0, -1)
  elseif ch_canread(channel) && ch_status(channel, options) =~# '^\%(open\|buffered\)$'
    return split(ch_read(channel, extend({'timeout': 0}, options)), s:newline, 1)
  endif
  return v:null
endfunction


" Job ----------------------------------------------------------------------
let s:job = {}

function! s:job.id() abort
  return str2nr(matchstr(string(self.__job), '^process \zs\d\+\ze'))
endfunction

" NOTE:
" On Unix a non-existing command results in "dead" instead
" So returns "dead" instead of "fail" even in non Unix.
function! s:job.status() abort
  let status = job_status(self.__job)
  return status ==# 'fail' ? 'dead' : status
endfunction

" NOTE:
" A Null character (\0) is used as a terminator of a string in Vim.
" Neovim can send \0 by using \n splitted list but in Vim.
" So replace all \n in \n splitted list to ''
function! s:job.send(data) abort
  let data = type(a:data) == s:t_list
        \ ? join(map(a:data, 'substitute(v:val, "\n", '''', ''g'')'), "\n")
        \ : a:data
  return ch_sendraw(self.__channel, data)
endfunction

function! s:job.stop() abort
  return job_stop(self.__job)
endfunction

function! s:job.wait(...) abort
  if !has('patch-8.0.0027')
    throw 'vital: System.Job: Vim 8.0.0026 and earlier is not supported.'
  endif
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
