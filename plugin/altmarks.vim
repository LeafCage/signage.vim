if exists('g:loaded_altmarks')| finish| endif| let g:loaded_altmarks = 1
let save_cpo = &cpo| set cpo&vim
let g:altmarks_lclib = 'v1'

"Variables "{{{
if !exists('g:altmarks_dir')
  let g:altmarks_dir = '~/.altmarks/'
endif
if !exists('g:altmarks_shiftgroup_pat')
  let g:altmarks_shiftgroup_pat = '@'
endif
let s:altmarks_dir = fnamemodify(g:altmarks_dir, ':p')
unlet g:altmarks_dir

if !exists('g:markgroups')
  let g:markgroups = [
        \{'name': 'Debug', 'limit':0, 'char': '修', 'linehl': 'linehl_blue', 'charhl': 'texthl_blue'},
        \{'name': 'Pending', 'limit':0, 'char': '途', 'linehl': 'linehl_yellow', 'charhl': 'texthl_yellow'},
        \{'name': 'Issue', 'limit':0, 'char': '問', 'linehl': 'linehl_red', 'charhl': 'texthl_red'},
        \{'name': 'Delete', 'limit':0, 'char': '消', 'linehl': 'linehl_purple', 'charhl': 'texthl_purple'},
        \{'name': 'Access', 'limit':0, 'char': '道', 'linehl': 'linehl_gray', 'charhl': 'texthl_gray'},
        \{'name': 'Note', 'limit':0, 'char': '記', 'linehl': 'linehl_green', 'charhl': 'texthl_green'},
        \]
endif
"Default: 特に設定なし
"Debug: 変更したところ
"Delete: 安全を確認したら後で消す
"crrent: 現在進行中
"Note: メモ
"TODO:
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
  "au BufRead * call <SID>Restore_sign()| let b:altmarks_lnum_changedvalue = 0
  au BufRead * call <SID>restore_sign()
  au BufEnter * let s:crrpath = expand('%:p')
  "au BufEnter * call <SID>restore_sign()
  au BufWritePost altmarks call <SID>updatealtmarks()
  au VimLeavePre * call <SID>write_markfile()
augroup END

function! s:restore_sign() "{{{
  let crrpath = expand('%:p')
  if exists('g:disable_sign_at_loaded') || crrpath == ''
    return
  endif
  let crrbufnr = bufnr('%')
  for pickedmark in s:markslist
    if pickedmark.path != crrpath
      continue
    endif
    for pickedgroup in g:markgroups
      if pickedmark.group != pickedgroup.name
        continue
      endif
      exe 'sign define '.pickedgroup['name'].' text='.pickedgroup['char'].' linehl='.pickedgroup['linehl'].' texthl='.pickedgroup['charhl']
      let sign_id = altmarks_port#make_signid(1,crrbufnr, pickedmark.pos[1])
      "let s:count_sign += 1
      exe 'sign place '.sign_id.' line='.pickedmark['pos'][1].' name='.pickedmark['group'].' file='.pickedmark['path']
    endfor
  endfor
  call altmarks_port#def_signhl()
endfunction "}}}
function! s:updatealtmarks() "{{{
  let tmp = readfile(s:altmarks_dir.'altmarks')
  let s:markslist = map(tmp, 'eval(v:val)')
endfunction "}}}
function! s:write_markfile() "{{{
  for picked in s:markslist
    if bufloaded(picked.path)
      let correctlnum_newid = s:registeredlnum2correctlnum(picked.pos[1], bufnr(picked.path))
      if correctlnum_newid[0] != picked.pos[1] "DebugLog: pickedではなくs:markslist[s:markslistpoi]を使っていたのを修正
        let picked.pos[1] = correctlnum_newid[0]
      endif
    endif
  endfor
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
noremap <silent> <Plug>(altmarks-groups-menu) :<C-u>call <SID>GroupsMenu(0)<CR>
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
if !hasmapto('<Plug>(altmarks-next)')
  nmap mj <Plug>(altmarks-next)
endif
if !hasmapto('<Plug>(altmarks-prev)')
  nmap mk <Plug>(altmarks-prev)
endif
if !hasmapto('<Plug>(altmarks-delete)')
  nmap md <Plug>(altmarks-delete)
endif
if !hasmapto('<Plug>(altmarks-status)')
  nmap ms <Plug>(altmarks-status)
endif
if !hasmapto('<Plug>(altmarks-clear)')
  nmap mc <Plug>(altmarks-clear)
endif
if !hasmapto('<Plug>(altmarks-groups-menu)')
  nmap mg <Plug>(altmarks-groups-menu)
endif
if !hasmapto('<Plug>(altmarks-onetime)')
  nmap mo <Plug>(altmarks-onetime)
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
if !hasmapto('<Plug>(altmarks-remove-plus)')
  nmap m- <Plug>(altmarks-remove-plus)
endif


function! s:shiftgroup(crrlnum,crrbufnr) "{{{
  let [registeredlnum, newlnum] = s:lnum_s_sign2registeredlnum(a:crrlnum, a:crrbufnr)
  let idx = s:mlpoi_whether_arglnummarked(registeredlnum)
  let s:markslistpoi = idx
  if newlnum != 0
    let s:markslist[idx].pos[1] = newlnum
  endif

  let sign_id = altmarks_port#make_signid(1, a:crrbufnr, s:markslist[idx].pos[1])
  exe 'sign unplace '.sign_id

  let s:markslist[idx].group = g:markgroups[s:grouppoi].name
  exe 'sign define '.g:markgroups[s:grouppoi]['name'].' text='.g:markgroups[s:grouppoi]['char'].' linehl='.g:markgroups[s:grouppoi]['linehl'].' texthl='.g:markgroups[s:grouppoi]['charhl']
  exe 'sign place '.sign_id.' line='.s:markslist[idx]['pos'][1].' name='.s:markslist[idx]['group'].' file='.s:markslist[idx]['path']
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
    "if pickedgroup.name == a:groupname_in_marklist && pickedgroup.enablesign == 1
    if pickedgroup.name == a:groupname_in_marklist
      sign unplace
    endif
  endfor
endfunction "}}}
function! s:chkandfix_markgap() "{{{
  silent let lnum_ids = lclib#{g:altmarks_lclib}#lnum_id_of_sign(0)
endfunction "}}}
"a:lnumにsignがあるなら、signIDから登録時の行番号を割り出す。
"登録時の行番と現在行sign行番が食い違っていたらsignIDを更新するが、s:markslist登録行数は修正しないので外部で "返値[1]!=0" の時を検出して修正しなければいけない。
"a:bufnrが0だと全てのバッファのsignから現在行のsignを探す
function! s:lnum_s_sign2registeredlnum(lnum, bufnr) "{{{
  silent let signs = lclib#{g:altmarks_lclib}#lnum_id_of_sign(a:bufnr)
  for picked in signs
    if picked[0] != a:lnum
      continue
    endif
    let registeredlnum = str2nr(matchstr(picked[1], '\d\{4}\zs\d\{5}'))
    let correctlnum = 0
    if registeredlnum != picked[0]
      let correctlnum = picked[0]
      exe 'sign unplace '.picked[1]
      exe 'sign place '.altmarks_port#make_signid(1,a:bufnr,a:lnum).' line='.a:lnum.' name='.picked[2].' buffer='.a:bufnr
    endif
    return [registeredlnum, correctlnum]
  endfor
  echoerr 'AltMarks: not found'
  return [0]
endfunction "}}}
"行番・バッファ番を元にsignIDを生成しそれを元に現在の正しいlnumを返す。signID更新
"lnum_sとの違い→lnum_sはsignの行番からサーチする（signをregisteredに変換する。）
"registeredlnum2はsignのIDから正しい行番をサーチする（registeredをsignに変換する）。
function! s:registeredlnum2correctlnum(lnum, bufnr) "{{{
  silent let signs = lclib#{g:altmarks_lclib}#lnum_id_of_sign(a:bufnr)
  let id = altmarks_port#make_signid(1, a:bufnr, a:lnum)
  for picked in signs
    if picked[1] != id
      continue
    endif
    let new_signID = picked[1]
    if a:lnum != picked[0]
      let lnumaftermoved = picked[0]
      exe 'sign unplace '.picked[1]
      let new_signID = altmarks_port#make_signid(1,a:bufnr,picked[0])
      exe 'sign place '.new_signID.' line='.picked[0].' name='.picked[2].' buffer='.a:bufnr
    endif
    return [picked[0], new_signID]
  endfor
  echoerr 'AltMarks: this buffer is not signed.'
endfunction "}}}
function! s:wRap_reged2jump(regedlnum, regedbufnr) "{{{
  let correctlnum_newid = s:registeredlnum2correctlnum(a:regedlnum, a:regedbufnr)
  if correctlnum_newid[0] != s:markslist[s:markslistpoi].pos[1]
    let s:markslist[s:markslistpoi].pos[1] = correctlnum_newid[0]
  endif

  if s:crrpath != s:markslist[s:markslistpoi]['path']
    silent exe 'edit '.s:markslist[s:markslistpoi]['path']
  endif
  call setpos('.', s:markslist[s:markslistpoi]['pos'])
  "silent exe 'sign jump '.correctlnum_newid[1].' file='.s:markslist[s:markslistpoi]['path']
endfunction "}}}
"(現在バッファの)引数行がマークとして登録されているか調べる。登録されているのならs:markslistの該当idxを返す
function! s:mlpoi_whether_arglnummarked(comparison_lnum) "{{{
  for picked in s:markslist
    if picked['path'] != s:crrpath
      continue
    endif
    "if picked['pos'][1] == line('.') || picked['pos'][1] >= line('$')
    if picked['pos'][1] == a:comparison_lnum
      return index(s:markslist, picked)
    endif
  endfor
  echoerr 'AltMarks: not found'
  return -1
endfunction "}}}


"m1-m9
function! s:Groupshift(idxnum) "{{{
  let s:chk_continue = 'groupshift'
  let markgroupsend = len(g:markgroups)-1
  let idxnum = a:idxnum-1 > markgroupsend ? markgroupsend : a:idxnum-1
  let s:grouppoi = idxnum
  let navi = s:make_navi('', -1)
  redraw|echo ''
  echo 'AltMarks: Set group at ['.g:markgroups[s:grouppoi]['name'].']'.navi
endfunction "}}}
"mo
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
"mc
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
"me
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
"md ms
function! s:Handlemark(command) "{{{
  let s:chk_continue = 'handlemark'
  let target = ''
  let attatch = ''
  let crrbufnr = bufnr('%')
  try
    let registeredlnum_newlnum = s:lnum_s_sign2registeredlnum(line('.'), crrbufnr)
    let idx = s:mlpoi_whether_arglnummarked(registeredlnum_newlnum[0])
  catch /AltMarks:.*/
    let navi = s:make_navi('',-1)
    redraw|echo ''
    echo 'AltMarks: Such mark is not found. ['.g:markgroups[s:grouppoi]['name'].'] '.navi
    return
  endtry
  let s:markslistpoi = idx
  let elements = s:markslist[s:markslistpoi]
  if registeredlnum_newlnum[1] != 0
    let elements.pos[1] = registeredlnum_newlnum[1]
  endif
  if a:command == 'Delete'
    let groupname = elements.group
    exe 'sign unplace '.altmarks_port#make_signid(1, crrbufnr, elements.pos[1])
    call remove(s:markslist, s:markslistpoi)
    let target .= elements['protect'].'['.elements['group'].'] "'.elements['ctx'].'" '
  elseif a:command == 'Status'
    let groupname = elements.group
    let target .= elements['protect'].'['.elements['group'].'] "'.elements['ctx'].'" '
    let attatch .= elements['attatch'].'  '
  endif
  redraw|echo ''
  "let navi = '('.s:markslistpoi.'/'.len(s:markslist).')'
  let navi = s:make_navi(groupname,-1)
  redraw|echo ''
  echo 'AltMarks'.a:command.': '.target.navi.attatch
endfunction "}}}
"mm mi ma
function! s:Registermarks(attatch) "{{{
  let s:chk_continue = 'registermarks'
  let crrinfo = altmarks_port#makecrrinfo(a:attatch)
  if empty(crrinfo)
    return
  endif
  let crrinfo.group = g:markgroups[s:grouppoi].name

  for picked in s:markslist "すでに登録されているmarkなら更新
    if [picked['path'],picked['pos'][1]] == [crrinfo['path'],crrinfo['pos'][1]]
      if a:attatch == 1
        let crrinfo['attatch'] = attatch
      elseif a:attatch == 2
        let crrinfo['attatch'] .= attatch
      else
        let crrinfo['attatch'] = picked['attatch']
      endif
      exe 'sign unplace '.altmarks_port#make_signid(1,bufnr('%'),picked.pos[1])
      call remove(s:markslist, index(s:markslist, picked))
    endif
  endfor

  "if g:markgroups[s:grouppoi].enablesign
  let crrbufnr = bufnr('%')
  exe 'sign define '.g:markgroups[s:grouppoi]['name'].' text='.g:markgroups[s:grouppoi]['char'].' linehl='.g:markgroups[s:grouppoi]['linehl'].' texthl='.g:markgroups[s:grouppoi]['charhl']
  "let s:count_sign += 1
  let sign_id = altmarks_port#make_signid(1,crrbufnr, crrinfo.pos[1])
  exe 'sign place '.sign_id.' line='.crrinfo['pos'][1].' name='.crrinfo['group'].' file='.crrinfo['path']
  call altmarks_port#def_signhl()
  "endif

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
"mj mk
function! s:Cycle_marks(ascending) "{{{
  let s:chk_continue = 'cyclemarks'
  if empty(s:markslist)
    let navi = s:make_navi('',-1)
    redraw|echo ''
    echo 'AltMarks: No marks is setted. ['.g:markgroups[s:grouppoi]['name'].'] '.navi
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
  let crrbufnr = bufnr('%')

  if bufloaded(s:markslist[s:markslistpoi].path)
    let return = 0
    try
      let registeredlnum_newlnum = s:lnum_s_sign2registeredlnum(crrpos[1], crrbufnr) "現在行hit_or_not
    catch /AltMarks:.*/
      let return = 2
    endtry
  else
    let return = altmarks_port#replay_mark(s:crrpath,crrpos, s:markslist[s:markslistpoi].path, s:markslist[s:markslistpoi].pos)
  endif

  if return == 2 "カーソルドがマーク行にないとき{{{
    call s:wRap_reged2jump(s:markslist[s:markslistpoi].pos[1], bufnr(s:markslist[s:markslistpoi].path))
    let return = 1
  endif
  if return
    call s:show_cycling(markslistend)
    return
  endif "}}}


  let s:markslistpoi = lclib#{g:altmarks_lclib}#cycle_poi(a:ascending, s:markslistpoi, markslistend)
  let s:markslistpoi = s:cycle_poi_in_group(a:ascending)

  if bufloaded(s:markslist[s:markslistpoi].path)
    call s:wRap_reged2jump(s:markslist[s:markslistpoi].pos[1], bufnr(s:markslist[s:markslistpoi].path))
  else
    call altmarks_port#replay_mark(s:crrpath,crrpos, s:markslist[s:markslistpoi]['path'], s:markslist[s:markslistpoi]['pos'])
  endif

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
"mg
function! s:GroupsMenu(shift) "{{{
  let s:chk_continue = 'groupsmenu'
  let markslistend = len(s:markslist)-1
  let markgroupsend = len(g:markgroups)-1

  let shift = a:shift ? 1 : 0
  let narrowedgroups = copy(g:markgroups)
  while len(narrowedgroups) > 1
    let menutext = ''
    let i = 1
    for picked in narrowedgroups
      let navi = substitute(s:make_navi(picked.name, markslistend), '(TTL:\d\+)', '','g')
      let menutext .= "(".i."): [".picked['name']."] ".navi."\n"
      let i +=1
    endfor

    let input = input("AltMarksGroupsMenu: [".g:markgroups[s:grouppoi]['name']."] (TTL:".(markslistend+1).")\n".menutext)
    if input == ''
      return
    endif
    if input =~ '\d\+'
      let idx = matchstr(input, '\d\+')-1
      let idx = idx>markgroupsend ? markgroupsend :idx
      let narrowedgroups = [remove(narrowedgroups, idx)]
    else
      if input =~ g:altmarks_shiftgroup_pat
        let input = substitute(input, g:altmarks_shiftgroup_pat, '', 'g')
        let shift = 1
      endif
      let input = substitute(substitute(input,'\s','\\\&.*','g'),'^','.*','g')

      call filter(narrowedgroups, 'v:val.name =~'''.input.'''')
    endif
    redraw|echo ''
  endwhile
  if !empty(narrowedgroups)
    let s:grouppoi = index(g:markgroups, narrowedgroups[0])
  endif

  let crrbufnr = bufnr('%')
  let crrlnum = line('.')
  try
    redraw|echo ''
    if shift
      call s:shiftgroup(crrlnum,crrbufnr)
    endif
  catch /AltMarks:.*/
    echo 'Here is no mark.'
  endtry

  let navi = s:make_navi('', markslistend)
  echo 'AltMarks: Set group at ['.g:markgroups[s:grouppoi]['name'].']'.navi
endfunction "}}}
"mh ml
function! s:Cycle_group(ascending) "{{{
  let s:chk_continue = 'cycle_group'
  let markgroupsend = len(g:markgroups)-1
  let s:grouppoi = lclib#{g:altmarks_lclib}#cycle_poi(a:ascending, s:grouppoi, markgroupsend)

  let crrlnum = line('.')
  let crrbufnr = bufnr('%')
  try
    call s:shiftgroup(crrlnum,crrbufnr)
  catch /AltMarks:.*/
  endtry

  redraw|echo ''
  let navi = s:make_navi('', -1)
  echo 'AltMarks: Set group at ['.g:markgroups[s:grouppoi]['name'].']'.navi
endfunction "}}}


let &cpo = save_cpo






"TODO
"mn mp グループを無視して全てのmarkをサイクルさせる
"mb mf 現在バッファ内に限定する／限定解除する
"mc
"limit属性 この数以上のマークは存在できない。越えたときは古いマークが削除
"mmの二度目の連打でHEAD^のマークへジャンプ
"添付メッセージをgrep
"unite表示
"グループサイクル方式でなく直接グループを指定してマークする各コマンド（commandにする？）
"mu でアップデート（posの変更
"現在のg:markgroupsに含まれていないs:markslist候補のグループの所属を起動時にDefaultやOtherに自動変更
"ビジュアル選択行を一気にsignする

"
"案:プラグインネーム変更　デバッグのサインツールだから…？signage.vim?
