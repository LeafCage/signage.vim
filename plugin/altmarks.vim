if exists('g:loaded_altmarks')| finish| endif| let g:loaded_altmarks = 1

"Variables "{{{
if !exists('g:altmarks_dir')
  let g:altmarks_dir = '~/.altmarks/'
endif
let s:altmarks_dir = fnamemodify(g:altmarks_dir, ':p')
unlet g:altmarks_dir

if !exists('g:markgroups')
  let g:markgroups = [
        \{'name': 'Default','enablesign':0, 'char': '', 'linehl': '', 'charhl': ''},
        \{'name': 'Debug','enablesign':1, 'char': '修', 'linehl': 'linehl_blue', 'charhl': 'texthl_blue'},
        \{'name': 'Delete','enablesign':1,  'char': '消', 'linehl': 'linehl_purple', 'charhl': 'texthl_purple'},
        \{'name': 'Issue','enablesign':1,  'char': '問', 'linehl': 'linehl_red', 'charhl': 'texthl_red'},
        \{'name': 'TODO','enablesign':1, 'char': 'TD', 'linehl': 'linehl_blue', 'charhl': 'texthl_yellow'},
        \{'name': 'Note','enablesign':1,  'char': '記', 'linehl': 'linehl_green', 'charhl': 'texthl_green'},
        \]
endif
"Default: 特に設定なし
"Debug: 変更したところ
"Delete: 安全を確認したら後で消す
"crrent: 現在進行中
"Note: メモ
"if filereadable(s:altmarks_dir.'markgroups')
"  let tmp = readfile(s:altmarks_dir.'markgroups')
"  let g:markgroups = map(tmp, 'eval(v:val)')
"endif
let s:grouppoi = 0
if exists('g:defa_grouppoi')
  let s:grouppoi = g:defa_grouppoi
  unlet g:starting_group
endif
let s:count_sign = 100
if exists('g:defa_count_sign')
  let s:count_sign = g:defa_count_sign
endif
let s:chk_continue = ''

let s:markslist = []
if filereadable(s:altmarks_dir.'altmarks')
  let tmp = readfile(s:altmarks_dir.'altmarks')
  let s:markslist = map(tmp, 'eval(v:val)')
endif
let s:markslistpoi = -1

 "}}}

augroup altmarks
  au!
  au BufRead * call <SID>Restore_sign()| let b:altmarks_lnum_changedvalue = 0
  au BufEnter * let s:crrpath = expand('%:p')
  au BufWritePost altmarks call <SID>Updatealtmarks()
  au VimLeavePre * call <SID>Write_markfile()
augroup END
function! s:Restore_sign() "{{{
  if exists('g:disable_sign_at_loaded')
    return
  endif
  let crrbufnr = bufnr('%')
  for pickedmark in s:markslist
    if pickedmark.path != s:crrpath
      continue
    endif
    for pickedgroup in g:markgroups
      if pickedmark.group != pickedgroup.name
        continue
      endif
      if pickedgroup.enablesign
        exe 'sign define '.pickedgroup['name'].' text='.pickedgroup['char'].' linehl='.pickedgroup['linehl'].' texthl='.pickedgroup['charhl']
        let sign_id = s:make_signid(1,crrbufnr, pickedmark.pos[1])
        "let s:count_sign += 1
        exe 'sign place '.sign_id.' line='.pickedmark['pos'][1].' name='.pickedmark['group'].' file='.pickedmark['path']
      endif
    endfor
  endfor
  call altmarks_port#def_signhl()
endfunction "}}}

function! s:Changedtick() "{{{
  if my_changedtick != b:changedtick
    let my_changedtick = b:changedtick
    call My_Update()
  endif
endfunction "}}}

function! s:Updatealtmarks() "{{{
  let tmp = readfile(s:altmarks_dir.'altmarks')
  let s:markslist = map(tmp, 'eval(v:val)')
endfunction "}}}

function! s:Write_markfile() "{{{
  let tmp = map(copy(s:markslist), 'string(v:val)')
  if len(tmp)
    if !isdirectory(s:altmarks_dir)
      call mkdir(s:altmarks_dir)
    endif
    call writefile(tmp, s:altmarks_dir.'altmarks')
  else
    call delete(s:altmarks_dir.'altmarks')
  endif

  "let tmp = map(copy(g:markgroups), 'string(v:val)')
  "if !isdirectory(s:altmarks_dir)
  "  call mkdir(s:altmarks_dir)
  "endif
  "call writefile(tmp, s:altmarks_dir.'markgroups')
endfunction "}}}

"au CursorMoved * call s:on_cursor_moved()
function! s:on_cursor_moved() "{{{
  "let crrpath = expand('%:p')
  let crrlnum = line('.')
  for picked in s:markslist
    if picked['path'] == s:crrpath && picked['pos'][1] == crrlnum
      call s:show_cycling(len(s:markslist)-1)
    else
    endif
  endfor
endfunction "}}}

"Mappings "{{{
noremap <silent> <Plug>(altmarks-marking) :<C-u>call <SID>Registermarks(0)<CR>
noremap <silent> <Plug>(altmarks-input) :<C-u>call <SID>Registermarks(1)<CR>
noremap <silent> <Plug>(altmarks-append) :<C-u>call <SID>Registermarks(2)<CR>
noremap <silent> <Plug>(altmarks-delete) :<C-u>call <SID>Handlemark('Delete')<CR>
noremap <silent> <Plug>(altmarks-remove-plus) :<C-u>call <SID>Handlemark('Remove plus')<CR>
noremap <silent> <Plug>(altmarks-next) :<C-u>call <SID>Cycle_marks(0)<CR>
noremap <silent> <Plug>(altmarks-prev) :<C-u>call <SID>Cycle_marks(1)<CR>
noremap <silent> <Plug>(altmarks-status) :<C-u>call <SID>Handlemark('Status')<CR>
noremap <silent> <Plug>(altmarks-group-Rcycle) :<C-u>call <SID>Cycle_group(0)<CR>
noremap <silent> <Plug>(altmarks-group-Lcycle) :<C-u>call <SID>Cycle_group(1)<CR>
noremap <silent> <Plug>(altmarks-group-shift1) :<C-u>call <SID>Groupshift(1)<CR>
noremap <silent> <Plug>(altmarks-group-shift2) :<C-u>call <SID>Groupshift(2)<CR>
noremap <silent> <Plug>(altmarks-group-shift3) :<C-u>call <SID>Groupshift(3)<CR>
noremap <silent> <Plug>(altmarks-group-shift4) :<C-u>call <SID>Groupshift(4)<CR>
noremap <silent> <Plug>(altmarks-group-shift5) :<C-u>call <SID>Groupshift(5)<CR>
noremap <silent> <Plug>(altmarks-group-shift6) :<C-u>call <SID>Groupshift(6)<CR>
noremap <silent> <Plug>(altmarks-group-shift7) :<C-u>call <SID>Groupshift(7)<CR>
noremap <silent> <Plug>(altmarks-group-shift8) :<C-u>call <SID>Groupshift(8)<CR>
noremap <silent> <Plug>(altmarks-group-shift9) :<C-u>call <SID>Groupshift(9)<CR>
noremap <silent> <Plug>(altmarks-edit) :<C-u>call <SID>Editmarksfile()<CR>
noremap <silent> <Plug>(altmarks-clear) :<C-u>call <SID>Clearmarks()<CR>
noremap <silent> <Plug>(altmarks-protect) :<C-u>call <SID>Handlemark('Protect')<CR>
noremap <silent> <Plug>(altmarks-onetime) :<C-u>call <SID>Putonetime()<CR>
if !hasmapto('<Plug>(altmarks-marking)')
  nmap mm <Plug>(altmarks-marking)
endif
if !hasmapto('<Plug>(altmarks-input)')
  nmap mi <Plug>(altmarks-input)
endif
if !hasmapto('<Plug>(altmarks-append)')
  nmap ma <Plug>(altmarks-append)
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
if !hasmapto('<Plug>(altmarks-status)')
  nmap ms <Plug>(altmarks-status)
endif
if !hasmapto('<Plug>(altmarks-onetime)')
  nmap mo <Plug>(altmarks-onetime)
endif
if !hasmapto('<Plug>(altmarks-clear)')
  nmap mc <Plug>(altmarks-clear)
endif
if !exists('g:disable_group_number_mapping')
  nmap m1 <Plug>(altmarks-group-shift1)
  nmap m2 <Plug>(altmarks-group-shift2)
  nmap m3 <Plug>(altmarks-group-shift3)
  nmap m4 <Plug>(altmarks-group-shift4)
  nmap m5 <Plug>(altmarks-group-shift5)
  nmap m6 <Plug>(altmarks-group-shift6)
  nmap m7 <Plug>(altmarks-group-shift7)
  nmap m8 <Plug>(altmarks-group-shift8)
  nmap m9 <Plug>(altmarks-group-shift9)
endif
"}}}

"デフォルトではキーマップを割り当てない予定
if !hasmapto('<Plug>(altmarks-group-Lcycle)')
  nmap mh <Plug>(altmarks-group-Lcycle)
endif
if !hasmapto('<Plug>(altmarks-group-Rcycle)')
  nmap ml <Plug>(altmarks-group-Rcycle)
endif
if !hasmapto('<Plug>(altmarks-edit)')
  nmap me <Plug>(altmarks-edit)
endif
if !hasmapto('<Plug>(altmarks-protect)')
  nmap mp <Plug>(altmarks-protect)
endif


function! s:make_signid(head,bufnr,lnum) "{{{
  return printf('%d%0.3d%0.5d', a:head, a:bufnr, a:lnum)
endfunction "}}}


function! s:make_navi(Groupname, Markslistend) "{{{
  let groupname = a:Groupname == '' ? g:markgroups[s:grouppoi].name : a:Groupname
  let markslistend = a:Markslistend == -1 ? len(s:markslist)-1 : a:Markslistend
  let groupcontents = 0
  let num_inthegroup = 0
  for picked in s:markslist
    if picked.group == groupname
      let groupcontents +=1
      if index(s:markslist,picked) == s:markslistpoi "今いるところ
        let num_inthegroup = groupcontents
      endif
    endif
  endfor
  return '('.num_inthegroup.'/'.groupcontents.')(TTL:'.(markslistend+1).')'
endfunction "}}}
function! s:sign_unplace(groupname_in_marklist) "{{{
  for pickedgroup in g:markgroups
    if pickedgroup.name == a:groupname_in_marklist && pickedgroup.enablesign == 1
      sign unplace
    endif
  endfor
endfunction "}}}



function! s:Cycle_group(ascending) "{{{
  let s:chk_continue = 'cycle_group'
  let markgroupsend = len(g:markgroups)-1
  let s:grouppoi = altmarks_port#cycle_poi(a:ascending, s:grouppoi, markgroupsend)
  let navi = s:make_navi('', -1)
  redraw|echo ''
  echo 'AltMarks: Set group at ['.g:markgroups[s:grouppoi]['name'].']'.navi
endfunction "}}}


function! s:Groupshift(idxnum) "{{{
  let s:chk_continue = 'groupshift'
  let markgroupsend = len(g:markgroups)-1
  let idxnum = a:idxnum-1 > markgroupsend ? markgroupsend : a:idxnum-1
  let s:grouppoi = idxnum
  let navi = s:make_navi('', -1)
  redraw|echo ''
  echo 'AltMarks: Set group at ['.g:markgroups[s:grouppoi]['name'].']'.navi
endfunction "}}}


function! s:MakeGroup() "{{{
  let s:chk_continue = 'makegroup'
  
endfunction "}}}


function! s:Putonetime() "{{{
  if s:chk_continue == 'putonetime'
  endif
  let s:chk_continue = 'putonetime'

  let crrinfo = altmarks_port#makecrrinfo(0)
  if empty(crrinfo)
    return
  endif
  let crrinfo.group = 'onetime'
  sign define altmarks_onetime text=OT texthl=lCursor
  let s:count_sign += 1
  exe 'sign place '. s:count_sign .' line='.crrinfo['pos'][1].' name=altmarks_onetime file='.crrinfo['path']
endfunction "}}}


function! s:Clearmarks() "{{{
  let s:chk_continue = 'clearmarks'
  let input = input("AltMarks: Now ".len(s:markslist)." marks. Which marks do you want to clear?(a/b/c/d)\na:No protected marks (in this buffer)\nb:No protected marks (in all buffer)\nc:All marks (in this buffer)\nd:All marks (in all buffer)\n" )
  if input == 'a'
    for picked in s:markslist
      if picked['protect'] == '' && picked['path'] == expand('%:p')
        call remove(s:markslist, index(s:markslist, picked))
      endif
    endfor
    let s:markslistpoi = len(s:markslist)-1
    redraw|echo ''
    echo 'AltMarks: Now '.len(s:markslist).' marks.'
  elseif input == 'b'
    for picked in s:markslist
      if picked['protect'] == ''
        call remove(s:markslist, index(s:markslist, picked))
      endif
    endfor
    let s:markslistpoi = len(s:markslist)-1
    redraw|echo ''
    echo 'AltMarks: Now '.len(s:markslist).' marks.'
  elseif input == 'c'
    for picked in s:markslist
      if picked['path'] == expand('%:p')
        call remove(s:markslist, index(s:markslist, picked))
      endif
    endfor
    let s:markslistpoi = len(s:markslist)-1
    redraw|echo ''
    echo 'AltMarks: Now '.len(s:markslist).' marks.'
  elseif input == 'd'
    let s:markslist = []
    let s:markslistpoi = 0
    redraw|echo ''
    echo 'AltMarks: Now '.len(s:markslist).' marks.'
  endif
endfunction "}}}


function! s:Editmarksfile() "{{{
  let s:chk_continue = 'editmarksfile'
  let tmp = map(copy(s:markslist), 'string(v:val)')
  if len(tmp)
    if !isdirectory(s:altmarks_dir)
      call mkdir(s:altmarks_dir)
    endif
    call writefile(tmp, s:altmarks_dir.'altmarks')
  else
    call delete(s:altmarks_dir.'altmarks')
  endif
  exe 'split '.s:altmarks_dir.'altmarks'
endfunction "}}}


function! s:Handlemark(command) "{{{
  let s:chk_continue = 'handlemark'
  let target = ''
  let attatch = ''
  for picked in s:markslist
    if picked['path'] != s:crrpath
      continue
    endif
    if picked['pos'][1] == line('.') || picked['pos'][1] >= line('$')
      let s:markslistpoi = index(s:markslist, picked)
      if a:command == 'Delete'
        let groupname = s:markslist[s:markslistpoi].group
        exe 'sign unplace '.s:make_signid(1, bufnr('%'), picked['pos'][1])
        call remove(s:markslist, s:markslistpoi)
        let target .= picked['protect'].'['.picked['group'].'] "'.picked['ctx'].'" '
      elseif a:command == 'Status'
        let groupname = s:markslist[s:markslistpoi].group
        let target .= picked['protect'].'['.picked['group'].'] "'.picked['ctx'].'" '
        let attatch .= picked['attatch'].'  '
      elseif a:command == 'Remove plus'
        let picked['plus'] = ' '
        let target .= picked['protect'].'"'.picked['ctx'].'" '
      elseif a:command == 'Protect'
        let picked['protect'] = picked['protect'] == '' ? '[*]' : ''
        let target .= picked['protect'].'"'.picked['ctx'].'" '
      endif
    endif
  endfor
  redraw|echo ''
  if target == ''
    echo 'AltMarks: Such mark is not found.'
  else
    "let navi = '('.s:markslistpoi.'/'.len(s:markslist).')'
    let navi = s:make_navi(groupname,-1)
    redraw|echo ''
    echo 'AltMarks'.a:command.': '.target.navi.attatch
  endif
endfunction "}}}


function! s:Registermarks(attatch) "{{{
  let s:chk_continue = 'registermarks'
  let crrinfo = altmarks_port#makecrrinfo(a:attatch)
  if empty(crrinfo)
    return
  endif
  let crrinfo.group = g:markgroups[s:grouppoi].name

  for picked in s:markslist "すでに登録されているmarkなら更新 CATALOGED2
    if [picked['path'],picked['pos'][1]] == [crrinfo['path'],crrinfo['pos'][1]]
      if a:attatch == 1
        let crrinfo['attatch'] = attatch
      elseif a:attatch == 2
        let crrinfo['attatch'] .= attatch
      else
        let crrinfo['attatch'] = picked['attatch']
      endif
      exe 'sign unplace '.s:make_signid(1,bufnr('%'),picked.pos[1])
      call remove(s:markslist, index(s:markslist, picked))
    endif
  endfor

  if g:markgroups[s:grouppoi].enablesign
    let crrbufnr = bufnr('%')
    exe 'sign define '.g:markgroups[s:grouppoi]['name'].' text='.g:markgroups[s:grouppoi]['char'].' linehl='.g:markgroups[s:grouppoi]['linehl'].' texthl='.g:markgroups[s:grouppoi]['charhl']
    "let s:count_sign += 1
    let sign_id = s:make_signid(1,crrbufnr, crrinfo.pos[1])
    exe 'sign place '.sign_id.' line='.crrinfo['pos'][1].' name='.crrinfo['group'].' file='.crrinfo['path']
    call altmarks_port#def_signhl()
  endif

  call add(s:markslist, crrinfo)
  let markslistend = len(s:markslist)-1
  let s:markslistpoi = markslistend
  call s:show_registered(markslistend, crrinfo)
endfunction "}}}
"登録した内容を表示する
function! s:show_registered(markslistend, crrentinfo)  "{{{1
  let navi = s:make_navi('',a:markslistend)
  redraw|echo ''
  echo 'AltMarksRegistered: '.printf('%s[%s] "%-20s" %s%s',
        \a:crrentinfo['protect'], a:crrentinfo['group'], a:crrentinfo['ctx'],
        \navi, a:crrentinfo['attatch'])
endfunction "}}}1



function! s:Cycle_marks(ascending) "{{{
  let s:chk_continue = 'cyclemarks'
  if empty(s:markslist)
    redraw|echo ''
    echo 'AltMarks: No marks is setted.'
    return
  endif

  let markslistend = len(s:markslist)-1
  if s:markslistpoi > markslistend
    let s:markslistpoi = markslistend
  endif

  if s:markslist[s:markslistpoi].group != g:markgroups[s:grouppoi].name
    let s:markslistpoi = -1
  endif
  if s:markslistpoi == -1 "poiが初期化されているとき
    let s:markslistpoi = a:ascending ? markslistend : 0
    let s:markslistpoi = s:cycle_poi_in_group(a:ascending)
    if s:markslistpoi == -1
      echo 'AltMarks: This group has no marks. ['.g:markgroups[s:grouppoi]['name'].']'
      return
    endif
  endif

  "let crrpath = expand('%:p')
  let crrpos = getpos('.')

  let return = altmarks_port#replay_mark(s:crrpath,crrpos, s:markslist[s:markslistpoi]['path'], s:markslist[s:markslistpoi]['pos'])
  if return
    call s:show_cycling(markslistend)
    return
  endif


  let s:markslistpoi = altmarks_port#cycle_poi(a:ascending, s:markslistpoi, markslistend)
  let s:markslistpoi = s:cycle_poi_in_group(a:ascending)

  "let s:markslistpoi = altmarks_port#cycle_poi(a:ascending, s:markslistpoi, markslistend)
  call altmarks_port#replay_mark(s:crrpath,crrpos, s:markslist[s:markslistpoi]['path'], s:markslist[s:markslistpoi]['pos'])
  call s:show_cycling(markslistend)
endfunction "}}}

"idxポインタをグループ内の次のmarkまでサイクルさせる（末尾でループ）
function! s:cycle_poi_in_group(ascending) "{{{
  let markslistend = len(s:markslist)-1
  let crrgroupname = g:markgroups[s:grouppoi].name
  if a:ascending
    let newpoi = s:nextpoi_in_group(1,0,s:markslistpoi,crrgroupname)
    if newpoi == -1
      let newpoi = s:nextpoi_in_group(1,s:markslistpoi,-1,crrgroupname)
    endif
  else
    let newpoi = s:nextpoi_in_group(0,s:markslistpoi,-1,crrgroupname)
    if newpoi == -1
      let newpoi = s:nextpoi_in_group(0,0,s:markslistpoi,crrgroupname)
    endif
  endif
  return newpoi
endfunction "}}}

function! s:nextpoi_in_group(ascending,start,stop,crrgroupname) "{{{
  let listpeace = s:markslist[(a:start):(a:stop)]
  if a:ascending
    call reverse(listpeace)
  endif
  for picked in listpeace
    if picked.group == a:crrgroupname
      return index(s:markslist, picked)
    endif
  endfor
  return -1
endfunction "}}}
"現在マークのステータス表示
function! s:show_cycling(markslistend) "{{{
  let navi = s:make_navi('',a:markslistend)
  redraw|echo ''
  echo 'AltMarks: '.printf('%s[%s] "%-20s" %s%s',
        \s:markslist[s:markslistpoi]['protect'], s:markslist[s:markslistpoi]['group'], s:markslist[s:markslistpoi]['ctx'],
        \navi, s:markslist[s:markslistpoi]['attatch'])
endfunction "}}}



"CATALOG:
"すでに登録されているmarkなら更新 CATALOGED2


"TODO
"添付メッセージをgrep
"unite表示
"sign id振り方を変更
"mh mlの挙動をやっぱりグループその場で変更にする
"ふせん。コメント。マーキング。グループ管理。テスト部分の記述に分かるようにsignできる。
"mu でアップデート（posの変更
"スクリプト中で重要だと思われる部分に付ける印
"issue: crrgroup Defの状態で他のを削除したらsignが解除されない
"スイッチしたときそのグループの含むマーク数を表示
"現在のg:markgroupsに含まれていないs:markslist候補のグループの所属を起動時にDefaultやOtherに自動変更
