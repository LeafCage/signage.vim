if !exists('g:altmarks_dir')
  let g:altmarks_dir = fnamemodify('~/', ':p')
endif

let s:markslist = []
if filereadable(fnamemodify(g:altmarks_dir, ':p').'.altmarks')
  let tmp = readfile(fnamemodify(g:altmarks_dir, ':p').'.altmarks')
  let s:markslist = map(tmp, 'eval(v:val)')
endif

let s:lastidx = -1


au BufWritePost .altmarks call <SID>updatealtmarks()
function! s:updatealtmarks() "{{{
  let tmp = readfile(fnamemodify(g:altmarks_dir, ':p').'.altmarks')
  let s:markslist = map(tmp, 'eval(v:val)')
  bdelete
endfunction "}}}

au VimLeavePre * call <SID>write_markfile()
function! s:write_markfile() "{{{
  let tmp = map(copy(s:markslist), 'string(v:val)')
  if len(tmp)
    if !isdirectory(fnamemodify(g:altmarks_dir, ':p'))
      call mkdir(fnamemodify(g:altmarks_dir, ':p'))
    endif
    call writefile(tmp, fnamemodify(g:altmarks_dir, ':p').'.altmarks')
  else
    call delete(fnamemodify(g:altmarks_dir, ':p').'.altmarks')
  endif
endfunction "}}}


noremap <silent> <Plug>(altmarks-marking) :<C-u>call <SID>registermarks(0)<CR>
noremap <silent> <Plug>(altmarks-attached) :<C-u>call <SID>registermarks(1)<CR>
noremap <silent> <Plug>(altmarks-delete) :<C-u>call <SID>handlemark('Delete')<CR>
noremap <silent> <Plug>(altmarks-remove-plus) :<C-u>call <SID>handlemark('Remove plus')<CR>
noremap <silent> <Plug>(altmarks-next) :<C-u>call <SID>cycle_marks(0)<CR>
noremap <silent> <Plug>(altmarks-prev) :<C-u>call <SID>cycle_marks(1)<CR>
noremap <silent> <Plug>(altmarks-edit) :<C-u>call <SID>editmarksfile()<CR>
noremap <silent> <Plug>(altmarks-clear) :<C-u>call <SID>clearmarks()<CR>
noremap <silent> <Plug>(altmarks-protect) :<C-u>call <SID>handlemark('Protect')<CR>
if !hasmapto('<Plug>(altmarks-marking)')
  nmap mm <Plug>(altmarks-marking)
endif
if !hasmapto('<Plug>(altmarks-attached)')
  nmap mi <Plug>(altmarks-attached)
endif
if !hasmapto('<Plug>(altmarks-delete)')
  nmap md <Plug>(altmarks-delete)
endif
if !hasmapto('<Plug>(altmarks-remove-plus)')
  nmap m- <Plug>(altmarks-remove-plus)
endif
if !hasmapto('<Plug>(altmarks-next)')
  nmap mj <Plug>(altmarks-next)
endif
if !hasmapto('<Plug>(altmarks-prev)')
  nmap mk <Plug>(altmarks-prev)
endif
if !hasmapto('<Plug>(altmarks-edit)')
  nmap me <Plug>(altmarks-edit)
endif
if !hasmapto('<Plug>(altmarks-clear)')
  nmap mc <Plug>(altmarks-clear)
endif
if !hasmapto('<Plug>(altmarks-protect)')
  nmap mp <Plug>(altmarks-protect)
endif
"com! altmarksList -nargs=0 call <SID>altmarksList()


function! s:clearmarks() "{{{
  let input = input("AltMarks: Now ".len(s:markslist)." marks. Which marks do you want to clear?(a/b/c/d)\na:No protected marks (in this buffer)\nb:No protected marks (in all buffer)\nc:All marks (in this buffer)\nd:All marks (in all buffer)\n" )
  if input == 'a'
    for picked in s:markslist
      if picked['protect'] == '' && picked['path'] == expand('%:p')
        call remove(s:markslist, index(s:markslist, picked))
      endif
    endfor
    let s:lastidx = len(s:markslist)-1
    redraw|echo ''
    echo 'AltMarks: Now '.len(s:markslist).' marks.'
  elseif input == 'b'
    for picked in s:markslist
      if picked['protect'] == ''
        call remove(s:markslist, index(s:markslist, picked))
      endif
    endfor
    let s:lastidx = len(s:markslist)-1
    redraw|echo ''
    echo 'AltMarks: Now '.len(s:markslist).' marks.'
  elseif input == 'c'
    for picked in s:markslist
      if picked['path'] == expand('%:p')
        call remove(s:markslist, index(s:markslist, picked))
      endif
    endfor
    let s:lastidx = len(s:markslist)-1
    redraw|echo ''
    echo 'AltMarks: Now '.len(s:markslist).' marks.'
  elseif input == 'd'
    let s:markslist = []
    let s:lastidx = 0
    redraw|echo ''
    echo 'AltMarks: Now '.len(s:markslist).' marks.'
  endif
endfunction "}}}


function! s:editmarksfile() "{{{
  let tmp = map(copy(s:markslist), 'string(v:val)')
  if len(tmp)
    if !isdirectory(fnamemodify(g:altmarks_dir, ':p'))
      call mkdir(fnamemodify(g:altmarks_dir, ':p'))
    endif
    call writefile(tmp, fnamemodify(g:altmarks_dir, ':p').'.altmarks')
  else
    call delete(fnamemodify(g:altmarks_dir, ':p').'.altmarks')
  endif
  exe 'split '.fnamemodify(g:altmarks_dir, ':p').'.altmarks'
endfunction "}}}


function! s:handlemark(command) "{{{
  let target = ''
  for picked in s:markslist
    if picked['path'] == expand('%:p')
      if picked['pos'][1] == getpos('.')[1] || picked['pos'][1] >= line('$')
        let s:lastidx = index(s:markslist, picked)
        if a:command == 'Delete'
          call remove(s:markslist, s:lastidx)
          let target .= picked['time'].picked['plus'].picked['protect'].'"'.picked['ctx'].'" '
        elseif a:command == 'Remove plus'
          let picked['plus'] = ''
          let target .= picked['time'].picked['plus'].picked['protect'].'"'.picked['ctx'].'" '
        elseif a:command == 'Protect'
          let picked['protect'] = picked['protect'] == '' ? '[*]' : ''
          let target .= picked['time'].picked['plus'].picked['protect'].'"'.picked['ctx'].'" '
        endif
      endif
    endif
  endfor
  redraw|echo ''
  if target == ''
    echo 'AltMarks: Such mark is not found.'
  else
    echo 'AltMarks: '.a:command.'; '.target
  endif
endfunction "}}}


function! s:registermarks(attatch) "{{{
  let attatch = ''
  if a:attatch
    let attatch = input('AltMarks: ')
    if attatch != ''
      let attatch = "\n".attatch
    else
      return
    endif
  endif

  let marktime = strftime('%y/%m/%d_%H:%M:%S')
  let col = col('.')
  let start = col-15 < 0 ? 0 :col-15
  let context = substitute(strtrans(getline('.')[(start):col+15]), '<\x\x>','','g')
  let currentinfo = {'time':marktime, 'path':expand('%:p'), 'pos':getpos('.'), 'ctx':context, 'attatch':attatch, 'plus': '', 'protect': ''}
  for picked in s:markslist
    if [picked['path'],picked['pos'][1]] == [currentinfo['path'],currentinfo['pos'][1]]
      let currentinfo['plus'] = picked['plus'].'+'
      let currentinfo['attatch'] = a:attatch ? attatch : picked['attatch']
      call remove(s:markslist, index(s:markslist, picked))
    endif
  endfor

  call add(s:markslist, currentinfo)
  let markslistlen = len(s:markslist)
  let navi = '('.markslistlen.'/'.markslistlen.')'
  redraw|echo ''
  echo 'AltMarks: Registered; '.currentinfo['time']. currentinfo['plus']. currentinfo['protect'].navi.'; "'. currentinfo['ctx'].'"'.currentinfo['attatch']
  let s:lastidx = markslistlen-1
endfunction "}}}


function! s:cycle_marks(ascending) "{{{
  if empty(s:markslist)
    redraw|echo ''
    echo 'AltMarks: No marks is setted.'
    return
  endif
  let markslistlen = len(s:markslist)-1
  if s:lastidx > markslistlen
    let s:lastidx = markslistlen
  endif
  let currentfile = expand('%:p')
  let currentpos = getpos('.')

  let return = 0
  if s:lastidx == -1
    let s:lastidx = a:ascending ? markslistlen : 0
  endif
  if currentfile != s:markslist[s:lastidx]['path']
    silent exe 'edit '. s:markslist[s:lastidx]['path']
    let return = 1
  endif
  if currentpos[1] != s:markslist[s:lastidx]['pos'][1] && currentpos[1] != line('$')
    call setpos('.', s:markslist[s:lastidx]['pos'])
    normal! zv
    let return = 1
  endif
  if return
    let navi = '('.(s:lastidx+1).'/'.(markslistlen+1).')'
    redraw|echo ''
    echo 'AltMarks: '.s:markslist[s:lastidx]['time']. s:markslist[s:lastidx]['plus'].s:markslist[s:lastidx]['protect']. navi.'; '.'"'.s:markslist[s:lastidx]['ctx'].'"'.s:markslist[s:lastidx]['attatch']
    return
  endif

  let s:lastidx = a:ascending ? s:lastidx-1 : s:lastidx+1
  if s:lastidx < 0
    let s:lastidx = markslistlen
  elseif s:lastidx > markslistlen
    let s:lastidx = 0
  else
  endif

  let file = s:markslist[s:lastidx]['path']
  if currentfile != file
    silent exe 'edit '. file
  endif
  let pos = s:markslist[s:lastidx]['pos']
  if currentpos != pos
    call setpos('.', pos)
    normal! zv
  endif

  let navi = '('.(s:lastidx+1).'/'.(markslistlen+1).')'
  redraw|echo ''
  echo 'AltMarks: '.s:markslist[s:lastidx]['time']. s:markslist[s:lastidx]['plus'].s:markslist[s:lastidx]['protect']. navi.'; '.'"'.s:markslist[s:lastidx]['ctx'].'"'.s:markslist[s:lastidx]['attatch']
endfunction "}}}


"TODO
"添付メッセージをgrep
"sign placeで見えるように
"unite表示
"mv カーソル行がマークされているか否か
