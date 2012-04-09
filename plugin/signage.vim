if exists('g:loaded_signage')| finish| endif| let g:loaded_signage = 1
let s:save_cpo = &cpo| set cpo&vim

"Variables "{{{
if !exists('g:signage_dir')
  let g:signage_dir = '~/.signage/'
endif
if !exists('g:signage_shiftgroup_pat')
  let g:signage_shiftgroup_pat = '@'
endif
let s:signage_dir = fnamemodify(g:signage_dir, ':p')
unlet g:signage_dir

if !exists('g:markgroups')
  let g:markgroups = [
        \{'name': 'Point', 'char': '点', 'linehl': 'linehl_gray', 'charhl': 'texthl_gray'},
        \{'name': 'Changed', 'char': '変', 'linehl': 'linehl_blue', 'charhl': 'texthl_blue'},
        \{'name': 'Advancing', 'char': '途', 'linehl': 'linehl_yellow', 'charhl': 'texthl_yellow'},
        \{'name': 'Later', 'char': '後', 'linehl': 'linehl_orange', 'charhl': 'texthl_orange'},
        \{'name': 'Issue', 'char': '問', 'linehl': 'linehl_red', 'charhl': 'texthl_red'},
        \{'name': 'Delete', 'char': '削', 'linehl': 'linehl_purple', 'charhl': 'texthl_purple'},
        \{'name': 'Note', 'char': '記', 'linehl': 'linehl_green', 'charhl': 'texthl_green'},
        \]
endif

let s:grouppoi = 0
if exists('g:defa_grouppoi')
  let s:grouppoi = g:defa_grouppoi
  unlet g:starting_group
endif
let s:chk_continue = ''

let s:markslist = []
if filereadable(s:signage_dir.'signage')
  let tmp = readfile(s:signage_dir.'signage')
  let s:markslist = map(tmp, 'eval(v:val)')
endif
let s:markslistpoi = -1

 "}}}



augroup signage
  au!
  au BufRead * call <SID>restore_sign()
  au BufEnter * let s:crrpath = expand('%:p')
  au BufWritePost signage call <SID>updatesignagefile()
  au VimLeavePre * call <SID>write_markfile()
augroup END

function! s:restore_sign() "{{{
  let crrpath = expand('%:p')
  if crrpath == ''
    return
  endif
  call s:optimize_sign(0,crrpath)
endfunction "}}}
function! s:updatesignagefile() "{{{
  let tmp = readfile(s:signage_dir.'signage')
  let s:markslist = map(tmp, 'eval(v:val)')
  silent for picked in lclib#lnum_id_of_sign(0)
    if picked[1] =~ '\d\{9}'
      exe 'sign unplace '.picked[1]
    endif
  endfor
  call s:optimize_sign(1,'')
endfunction "}}}
function! s:write_markfile() "{{{
  call s:cHk_allmarks_correctness()
  call s:make_signage_file()
endfunction "}}}


"Keybinds "{{{
noremap <silent> <Plug>(signage-groups-menu) :<C-u>call <SID>GroupsMenu(0)<CR>
noremap <silent> <Plug>(signage-groups-menu-shift) :<C-u>call <SID>GroupsMenu(1)<CR>
noremap <silent> <Plug>(signage-marking) :<C-u>call <SID>Registermarks(0)<CR>
noremap <silent> <Plug>(signage-input) :<C-u>call <SID>Registermarks(1)<CR>
noremap <silent> <Plug>(signage-append) :<C-u>call <SID>Registermarks(2)<CR>
noremap <silent> <Plug>(signage-delete) :<C-u>call <SID>Handlemark('Delete')<CR>
noremap <silent> <Plug>(signage-status) :<C-u>call <SID>Handlemark('Status')<CR>
noremap <silent> <Plug>(signage-next) :<C-u>call <SID>Cycle_marks(0,0)<CR>
noremap <silent> <Plug>(signage-prev) :<C-u>call <SID>Cycle_marks(1,0)<CR>
noremap <silent> <Plug>(signage-next-all) :<C-u>call <SID>Cycle_marks(0,1)<CR>
noremap <silent> <Plug>(signage-prev-all) :<C-u>call <SID>Cycle_marks(1,1)<CR>
noremap <silent> <Plug>(signage-group-Rcycle) :<C-u>call <SID>Cycle_group(0)<CR>
noremap <silent> <Plug>(signage-group-Lcycle) :<C-u>call <SID>Cycle_group(1)<CR>
"noremap <silent> <Plug>(signage-group-shift1) :<C-u>call <SID>Groupshift(1)<CR>
"noremap <silent> <Plug>(signage-group-shift2) :<C-u>call <SID>Groupshift(2)<CR>
"noremap <silent> <Plug>(signage-group-shift3) :<C-u>call <SID>Groupshift(3)<CR>
"noremap <silent> <Plug>(signage-group-shift4) :<C-u>call <SID>Groupshift(4)<CR>
"noremap <silent> <Plug>(signage-group-shift5) :<C-u>call <SID>Groupshift(5)<CR>
"noremap <silent> <Plug>(signage-group-shift6) :<C-u>call <SID>Groupshift(6)<CR>
"noremap <silent> <Plug>(signage-group-shift7) :<C-u>call <SID>Groupshift(7)<CR>
"noremap <silent> <Plug>(signage-group-shift8) :<C-u>call <SID>Groupshift(8)<CR>
"noremap <silent> <Plug>(signage-group-shift9) :<C-u>call <SID>Groupshift(9)<CR>
noremap <silent> <Plug>(signage-edit) :<C-u>call <SID>Editmarksfile()<CR>
noremap <silent> <Plug>(signage-clear) :<C-u>call <SID>Clearmarks()<CR>
"noremap <silent> <Plug>(signage-onetime) :<C-u>call <SID>Putonetime()<CR>
noremap <silent> <Plug>(signage-toggle-crrbuf-only) :<C-u>call <SID>Crrbuf_only()<CR>
if !get(g:,'disable_defa_binds')
  if !hasmapto('<Plug>(signage-marking)')
    nmap mm <Plug>(signage-marking)
  endif
  if !hasmapto('<Plug>(signage-input)')
    nmap mi <Plug>(signage-input)
  endif
  if !hasmapto('<Plug>(signage-append)')
    nmap ma <Plug>(signage-append)
  endif
  if !hasmapto('<Plug>(signage-next)')
    nmap mj <Plug>(signage-next)
  endif
  if !hasmapto('<Plug>(signage-prev)')
    nmap mk <Plug>(signage-prev)
  endif
  if !hasmapto('<Plug>(signage-next-all)')
    nmap mn <Plug>(signage-next-all)
  endif
  if !hasmapto('<Plug>(signage-prev-all)')
    nmap mp <Plug>(signage-prev-all)
  endif
  if !hasmapto('<Plug>(signage-delete)')
    nmap md <Plug>(signage-delete)
  endif
  if !hasmapto('<Plug>(signage-status)')
    nmap ms <Plug>(signage-status)
  endif
  if !hasmapto('<Plug>(signage-clear)')
    nmap mc <Plug>(signage-clear)
  endif
  if !hasmapto('<Plug>(signage-groups-menu)')
    nmap mg <Plug>(signage-groups-menu)
  endif
  if !hasmapto('<Plug>(signage-group-Lcycle)')
    nmap mh <Plug>(signage-group-Lcycle)
  endif
  if !hasmapto('<Plug>(signage-group-Rcycle)')
    nmap ml <Plug>(signage-group-Rcycle)
  endif
  if !hasmapto('<Plug>(signage-toggle-crrbuf-only)')
    nmap mo <Plug>(signage-toggle-crrbuf-only)
  endif
  if !hasmapto('<Plug>(signage-edit)')
    nmap mq <Plug>(signage-edit)
  endif
endif
"}}}

"Commands
com! -nargs=? SignageSetmark call <SID>Setmark(<f-args>)
com! -nargs=0 SignageFixInvalidGroups call <SID>Find_invalidgroups(1)
com! -nargs=0 SignageEditfile call <SID>Editmarksfile()


function! s:optimize_sign(allbuffers,path) "{{{
  let path = a:path
  let bufnr = bufnr(path)
  for pickedmark in s:markslist
    if a:allbuffers
      if !bufloaded(pickedmark.path)
        continue
      endif
      let path = pickedmark.path
      let bufnr = bufnr(path)
    else
      if pickedmark.path != path
        continue
      endif
    endif

    let breakpicked = 0
    for chk_dup in s:markslist
      if chk_dup.path != path || chk_dup == pickedmark
        continue
      endif
      if chk_dup.pos[1] == pickedmark.pos[1]
        call remove(s:markslist, index(s:markslist, pickedmark))
        let breakpicked = 1
        break
      endif
    endfor
    if breakpicked
      continue
    endif

    for pickedgroup in g:markgroups
      if pickedmark.group != pickedgroup.name
        continue
      endif
      exe 'sign define '.pickedgroup['name'].' text='.pickedgroup['char'].' linehl='.pickedgroup['linehl'].' texthl='.pickedgroup['charhl']
      let sign_id = signage_port#make_signid(1, bufnr, pickedmark.pos[1])
      exe 'sign unplace '.sign_id
      exe 'sign place '.sign_id.' line='.pickedmark['pos'][1].' name='.pickedmark['group'].' file='.pickedmark['path']
    endfor
  endfor
  call signage_port#def_signhl()
endfunction "}}}
function! s:make_signage_file() "{{{
  let tmp = map(copy(s:markslist), 'string(v:val)')
  if len(tmp)
    if !isdirectory(s:signage_dir)
      call mkdir(s:signage_dir)
    endif
    call writefile(tmp, s:signage_dir.'signage')
  else
    call delete(s:signage_dir.'signage')
  endif
endfunction "}}}
function! s:cHk_allmarks_correctness() "{{{
  for picked in s:markslist
    if bufloaded(picked.path)
      let [correctlnum,newid] = s:registeredlnum2correctlnum(picked.pos[1], bufnr(picked.path))
      if correctlnum != picked.pos[1]
        let picked.pos[1] = correctlnum
      endif
    endif
  endfor
endfunction "}}}
function! s:shiftgroup(crrlnum,crrbufnr) "{{{
  let [registeredlnum, newlnum] = s:lnum_s_sign2registeredlnum(a:crrlnum, a:crrbufnr)
  let idx = s:mlpoi_whether_arglnummarked(registeredlnum)
  let s:markslistpoi = idx
  if newlnum != 0
    let s:markslist[idx].pos[1] = newlnum
  endif

  let sign_id = signage_port#make_signid(1, a:crrbufnr, s:markslist[idx].pos[1])
  call s:shiftgroup_update_sign(idx, s:grouppoi,sign_id)
endfunction "}}}
function! s:shiftgroup_update_sign(marklistidx, groupsidx, sign_id) "{{{
  exe 'sign unplace '.a:sign_id

  let s:markslist[a:marklistidx].group = g:markgroups[a:groupsidx].name
  exe 'sign define '.g:markgroups[a:groupsidx]['name'].' text='.g:markgroups[a:groupsidx]['char'].' linehl='.g:markgroups[a:groupsidx]['linehl'].' texthl='.g:markgroups[a:groupsidx]['charhl']
  exe 'sign unplace '.a:sign_id
  exe 'sign place '.a:sign_id.' line='.s:markslist[a:marklistidx]['pos'][1].' name='.s:markslist[a:marklistidx]['group'].' file='.s:markslist[a:marklistidx]['path']
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
function! s:chkandfix_markgap() "{{{
  silent let lnum_ids = lclib#lnum_id_of_sign(0)
endfunction "}}}
"a:lnumにsignがあるなら、signIDから登録時の行番号を割り出す。
"登録時の行番と現在行sign行番が食い違っていたらsignIDを更新するが、s:markslist登録行数は修正しないので外部で "返値[1]!=0" の時を検出して修正しなければいけない。
"a:bufnrが0だと全てのバッファのsignから現在行のsignを探す
function! s:lnum_s_sign2registeredlnum(lnum, bufnr) "{{{
  silent let signs = lclib#lnum_id_of_sign(a:bufnr)
  for picked in signs
    if picked[0] != a:lnum
      continue
    endif
    let registeredlnum = str2nr(matchstr(picked[1], '\d\{4}\zs\d\{5}'))
    let correctlnum = 0
    if registeredlnum != picked[0]
      let correctlnum = picked[0]
      exe 'sign unplace '.picked[1]
      let newID = signage_port#make_signid(1,a:bufnr,a:lnum)
      exe 'sign unplace '.newID
      exe 'sign place '.newID.' line='.a:lnum.' name='.picked[2].' buffer='.a:bufnr
    endif
    return [registeredlnum, correctlnum]
  endfor
  echoerr 'Signage: not found'
  return [0]
endfunction "}}}
"行番・バッファ番を元にsignIDを生成しそれを元に現在の正しいlnumとnewIDを返す。signID更新。返値newIDは今のところ有効活用されてない
"lnum_sとの違い→lnum_sはsignの行番からサーチする（signをregisteredに変換する。）
"registeredlnum2はsignのIDから正しい行番をサーチする（registeredをsignに変換する）。
function! s:registeredlnum2correctlnum(lnum, bufnr) "{{{
  silent let signs = lclib#lnum_id_of_sign(a:bufnr)
  let id = signage_port#make_signid(1, a:bufnr, a:lnum)
  for picked in signs
    if picked[1] != id
      continue
    endif
    let new_signID = picked[1]
    if a:lnum != picked[0]
      let lnumaftermoved = picked[0]
      exe 'sign unplace '.picked[1]
      let new_signID = signage_port#make_signid(1,a:bufnr,picked[0])
      exe 'sign place '.new_signID.' line='.picked[0].' name='.picked[2].' buffer='.a:bufnr
    endif
    return [picked[0], new_signID]
  endfor
  echoerr 'Signage: this buffer is not signed.'
endfunction "}}}
function! s:wRap_reged2jump(regedlnum, regedbufnr) "{{{
  try
    let [correctlnum,newid] = s:registeredlnum2correctlnum(a:regedlnum, a:regedbufnr)
  catch /Signage:.\{-}not.\{-}
    if !isdirectory(s:signage_dir)
      call mkdir(s:signage_dir)
    endif
    call writefile(map([s:markslist[s:markslistpoi].pos, s:markslist[s:markslistpoi].path, s:markslist[s:markslistpoi].group, expand('<sfile>')], 'string(v:val)'), s:signage_dir.'.signage_err_wRap')
    return 1
  endtry
  if correctlnum != s:markslist[s:markslistpoi].pos[1]
    let s:markslist[s:markslistpoi].pos[1] = correctlnum
  endif

  if s:crrpath != s:markslist[s:markslistpoi]['path']
    silent exe 'edit '.s:markslist[s:markslistpoi]['path']
  endif
  call setpos('.', s:markslist[s:markslistpoi]['pos'])
  normal! zv
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
  echoerr 'Signage: not found'
  return -1
endfunction "}}}


"旧m1-m9
function! s:Groupshift(idxnum) "{{{
  let s:chk_continue = 'groupshift'
  let markgroupsend = len(g:markgroups)-1
  let idxnum = a:idxnum-1 > markgroupsend ? markgroupsend : a:idxnum-1
  let s:grouppoi = idxnum
  let navi = s:make_navi('', -1)
  redraw|echo ''
  echo 'Signage: Set group at ['.g:markgroups[s:grouppoi]['name'].']'.navi
endfunction "}}}
"旧mo
"let s:count_sign = 100 "{{{
"function! s:Putonetime()
"  if s:chk_continue == 'putonetime'
"  endif
"  let s:chk_continue = 'putonetime'
"
"  let crrinfo = signage_port#makecrrinfo(0)
"  if empty(crrinfo)
"    return
"  endif
"  let crrinfo.group = 'onetime'
"  sign define signage_onetime text=OT texthl=lCursor
"  let s:count_sign += 1
"  exe 'sign place '. s:count_sign .' line='.crrinfo['pos'][1].' name=signage_onetime file='.crrinfo['path']
"endfunction "}}}
"mc
function! s:Clearmarks() "{{{
  let s:chk_continue = 'clearmarks'
  let markslistend = len(s:markslist)-1
  let crrgroup = g:markgroups[s:grouppoi].name
  let groupstatus = s:make_menu_selgroup(g:markgroups, markslistend)
  let input = input("SignageClearmarks: [".g:markgroups[s:grouppoi]['name']."] (TTL:".(markslistend+1).") (a/b/c/d)\n".groupstatus."(a):In current buffer, the current group.\n(b):In current buffer, all groups.\n(c):In all buffers, the current group.\n(d):In all buffers, all groups.\n" )
  if input == 'a'
    for picked in s:markslist
      if picked.group == g:markgroups[s:grouppoi].name && picked.path == s:crrpath
        exe 'sign unplace '.signage_port#make_signid(1,bufnr('%'),picked.pos[1])
        call remove(s:markslist, index(s:markslist, picked))
      endif
    endfor
  elseif input == 'b'
    for picked in s:markslist
      if picked.path == s:crrpath
        exe 'sign unplace '.signage_port#make_signid(1,bufnr('%'),picked.pos[1])
        call remove(s:markslist, index(s:markslist, picked))
      endif
    endfor
  elseif input == 'c'
    for picked in s:markslist
      if picked.group == g:markgroups[s:grouppoi].name
        if bufloaded(picked.path)
          exe 'sign unplace '.signage_port#make_signid(1,bufnr(picked.path),picked.pos[1])
        endif
        call remove(s:markslist, index(s:markslist, picked))
      endif
    endfor
  elseif input == 'd'
    for picked in s:markslist
      if bufloaded(picked.path)
        exe 'sign unplace '.signage_port#make_signid(1,bufnr(picked.path),picked.pos[1])
      endif
    endfor
    let s:markslist = []
  else
    return
  endif
  redraw|echo ''
  let navi = s:make_navi(crrgroup, len(s:markslist)-1)
  echo 'Signage: ['.crrgroup.'] '.navi
  let s:markslistpoi = -1
  call s:neutralizeSignColumn()
endfunction "}}}
"mq
function! s:Editmarksfile() "{{{
  let s:chk_continue = 'editmarksfile'
  call s:cHk_allmarks_correctness()
  call s:make_signage_file()
  exe 'split '.s:signage_dir.'signage'
endfunction "}}}
"md ms
function! s:Handlemark(command) "{{{
  let s:chk_continue = 'handlemark'
  let target = ''
  let attach = ''
  let crrbufnr = bufnr('%')
  try
    let [registeredlnum,newlnum] = s:lnum_s_sign2registeredlnum(line('.'), crrbufnr)
    let idx = s:mlpoi_whether_arglnummarked(registeredlnum)
  catch /Signage:.\{-}not.\{-}/
    let navi = s:make_navi('',-1)
    redraw|echo ''
    echo 'Signage: Such mark is not found. ['.g:markgroups[s:grouppoi]['name'].'] '.navi
    return
  endtry
  let s:markslistpoi = idx
  let elements = s:markslist[s:markslistpoi]
  if newlnum != 0
    let elements.pos[1] = newlnum
  endif
  if a:command == 'Delete'
    let groupname = elements.group
    let target .= '['.elements['group'].'] "'.elements['ctx'].'" '
    call s:deletemark(crrbufnr, elements.pos[1])
  elseif a:command == 'Status'
    let groupname = elements.group
    let target .= '['.elements['group'].'] "'.elements['ctx'].'" '
    let attach .= elements['attach'].'  '
  endif
  redraw|echo ''
  let navi = s:make_navi(groupname,-1)
  redraw|echo ''
  echo 'Signage'.a:command.': '.target.navi.' '.attach
endfunction "}}}
function! s:deletemark(crrbufnr,lnum) "{{{
  exe 'sign unplace '.signage_port#make_signid(1, a:crrbufnr, a:lnum)
  call remove(s:markslist, s:markslistpoi)
  let s:markslistpoi = -1 "ここでpoiリセットしておかないとbufonlyを破ることがある
  silent if empty(lclib#lnum_id_of_sign(a:crrbufnr))
    call s:neutralizeSignColumn()
  endif
endfunction "}}}
"mm mi ma
function! s:Registermarks(attach) "{{{
  let s:chk_continue = 'registermarks'
  let crrinfo = signage_port#makecrrinfo(a:attach)
  if empty(crrinfo)
    return
  endif
  let crrinfo.group = g:markgroups[s:grouppoi].name
  let crrbufnr = bufnr('%')

  let groupname = s:register(a:attach,crrinfo,crrbufnr,s:grouppoi,0)

  call s:show_registered(groupname, s:grouppoi)
endfunction "}}}
function! s:register(attach,crrinfo,crrbufnr,grouppoi,nodelete) "{{{
  let groupname = ''
  try
    let [registeredlnum,newlnum] = s:lnum_s_sign2registeredlnum(a:crrinfo.pos[1], a:crrbufnr)
    let mlidx = s:mlpoi_whether_arglnummarked(registeredlnum)
    let novirgin = 1
  catch /Signage:.\{-}not.\{-}/ "登録されていない(初登録の時)
    let novirgin = 0
    for picked in s:markslist
      if [picked.path,picked.pos[1]] == [a:crrinfo.path,a:crrinfo.pos[1]]
        let novirgin = 1
      endif
    endfor
  endtry

  if novirgin
    let s:markslistpoi = mlidx
    if newlnum != 0
      let s:markslist[s:markslistpoi].pos[1] = newlnum
    endif
    if a:attach == 1
      let s:markslist[s:markslistpoi].attach = a:crrinfo.attach
    elseif a:attach == 2
      let s:markslist[s:markslistpoi].attach .= a:crrinfo.attach
    elseif a:nodelete
      let s:markslist[s:markslistpoi].group = a:crrinfo.group
      let sign_id = signage_port#make_signid(1, a:crrbufnr, s:markslist[mlidx].pos[1])
      call s:shiftgroup_update_sign(mlidx, a:grouppoi, sign_id)
    else
      let groupname = s:markslist[s:markslistpoi].group
      call s:deletemark(a:crrbufnr, s:markslist[s:markslistpoi].pos[1])
      let navi = s:make_navi(groupname,-1)
    endif
  endif

  if !novirgin
    exe 'sign define '.g:markgroups[a:grouppoi]['name'].' text='.g:markgroups[a:grouppoi]['char'].' linehl='.g:markgroups[a:grouppoi]['linehl'].' texthl='.g:markgroups[a:grouppoi]['charhl']
    let sign_id = signage_port#make_signid(1,a:crrbufnr, a:crrinfo.pos[1])
    exe 'sign unplace '.sign_id
    exe 'sign place '.sign_id.' line='.a:crrinfo['pos'][1].' name='.a:crrinfo['group'].' file='.a:crrinfo['path']
    call signage_port#def_signhl()

    call add(s:markslist, a:crrinfo)
    let s:markslistpoi = len(s:markslist)-1
  endif
  return groupname
endfunction "}}}
"登録した内容を表示する
function! s:show_registered(groupname, groupsidx)  "{{{1
  let navi = s:make_navi(a:groupname, -1)
  let showattach = s:markslistpoi==-1 ? '' : s:markslist[s:markslistpoi]['attach']
  redraw|echo ''
  "echo 'signageRegistered: '.printf('[%s] "%-20s" %s %s',
        "\s:markslist[s:markslistpoi]['group'], s:markslist[s:markslistpoi]['ctx'],
        "\navi, s:markslist[s:markslistpoi]['attach'])
  echo 'SignageRegistered: '.printf('[%s] %s %s',
        \g:markgroups[a:groupsidx]['name'],
        \navi, showattach)
endfunction "}}}1
"mj mk mn mp
function! s:Cycle_marks(ascending, allgroups) "{{{
  let s:chk_continue = 'cyclemarks'
  if empty(s:markslist)
    let navi = s:make_navi('',-1)
    redraw|echo ''
    echo 'Signage: No marks is setted. ['.g:markgroups[s:grouppoi]['name'].'] '.navi
    return
  endif

  let markslistend = len(s:markslist)-1
  if s:markslistpoi > markslistend
    let s:markslistpoi = markslistend
  endif

  if s:markslist[s:markslistpoi].group != g:markgroups[s:grouppoi].name && !a:allgroups
    let s:markslistpoi = -1
  endif
  if s:markslistpoi == -1 "poiが初期化されているとき
    let s:markslistpoi = a:ascending ? markslistend : 0
    while 1
      if s:markslist[s:markslistpoi].path != s:crrpath && s:signage_bufonly == 1
        let s:markslistpoi = lclib#cycle_poi(a:ascending, s:markslistpoi, markslistend)
        continue
      endif
      break
    endwhile
    if !a:allgroups
      while 1
        let s:markslistpoi = s:cycle_poi_in_group(a:ascending)
        if s:markslistpoi == -1
          echo 'Signage: This group has no marks. ['.g:markgroups[s:grouppoi]['name'].']'
          return
        elseif s:markslist[s:markslistpoi].path != s:crrpath && s:signage_bufonly == 1
          continue
        endif
        break
      endwhile
    endif
  endif

  "let crrpath = expand('%:p')
  let crrpos = getpos('.')
  let crrbufnr = bufnr('%')

  if bufloaded(s:markslist[s:markslistpoi].path)
    let return = 0
    try
      let registeredlnum_newlnum = s:lnum_s_sign2registeredlnum(crrpos[1], crrbufnr) "現在行hit_or_not
    catch /Signage:.\{-}not.\{-}/
      let return = 2
    endtry
  else
    let return = signage_port#replay_mark(s:crrpath,crrpos, s:markslist[s:markslistpoi].path, s:markslist[s:markslistpoi].pos)
  endif

  if return == 2 "カーソルがマーク行にないとき{{{
    if s:wRap_reged2jump(s:markslist[s:markslistpoi].pos[1], bufnr(s:markslist[s:markslistpoi].path))
      call remove(s:markslist, s:markslistpoi)
      let s:markslistpoi = a:ascending ? s:markslistpoi : s:markslistpoi-1
      return
    endif
    let return = 1
  endif
  if return
    call s:show_cycling(markslistend)
    return
  endif "}}}


  while 1
    let s:markslistpoi = lclib#cycle_poi(a:ascending, s:markslistpoi, markslistend)
    if s:markslist[s:markslistpoi].path != s:crrpath && s:signage_bufonly == 1
      continue
    endif
    break
  endwhile
  if !a:allgroups
    while 1
      let s:markslistpoi = s:cycle_poi_in_group(a:ascending)
      if s:markslist[s:markslistpoi].path != s:crrpath && s:signage_bufonly == 1
        continue
      endif
      break
    endwhile
  endif

  if bufloaded(s:markslist[s:markslistpoi].path)
    if s:wRap_reged2jump(s:markslist[s:markslistpoi].pos[1], bufnr(s:markslist[s:markslistpoi].path))
      call remove(s:markslist, s:markslistpoi)
      let s:markslistpoi = a:ascending ? s:markslistpoi : s:markslistpoi-1
      call s:Cycle_marks(a:ascending, a:allgroups)
      return
    endif
  else
    call signage_port#replay_mark(s:crrpath,crrpos, s:markslist[s:markslistpoi]['path'], s:markslist[s:markslistpoi]['pos'])
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
  "echo 'Signage: '.printf('[%s] "%-20s" %s%s',
        "\s:markslist[s:markslistpoi]['group'], s:markslist[s:markslistpoi]['ctx'],
        "\navi, s:markslist[s:markslistpoi]['attach'])
  echo 'Signage: '.printf('[%s] %s%s',
        \s:markslist[s:markslistpoi]['group'],
        \navi, s:markslist[s:markslistpoi]['attach'])
endfunction "}}}
"mg
function! s:GroupsMenu(shift) "{{{
  let s:chk_continue = 'groupsmenu'
  let markslistend = len(s:markslist)-1
  let markgroupsend = len(g:markgroups)-1

  let shift = a:shift ? 1 : 0
  let groupsclone = copy(g:markgroups)
  let firsttime = 1
  while len(groupsclone) > 1
    let menutext = s:make_menu_selgroup(groupsclone,markslistend)

    let input = input("SignageGroupsMenu: [".g:markgroups[s:grouppoi]['name']."] (TTL:".(markslistend+1).")\n".menutext)
    if input == ''
      return
    endif
    if input =~ g:signage_shiftgroup_pat
      let input = substitute(input, g:signage_shiftgroup_pat, '', 'g')
      let shift = 1
    endif
    let groupsclone = s:menu_select_group(firsttime,input,groupsclone)
    let firsttime = 0
    redraw|echo ''
  endwhile
  if !empty(groupsclone)
    let s:grouppoi = index(g:markgroups, groupsclone[0])
  endif

  let crrbufnr = bufnr('%')
  let crrlnum = line('.')
  try
    redraw|echo ''
    if shift
      call s:shiftgroup(crrlnum,crrbufnr)
    endif
  catch /Signage:.\{-}not.\{-}/
    echo 'Here is no mark.'
  endtry

  let navi = s:make_navi('', markslistend)
  echo 'Signage: Set group at ['.g:markgroups[s:grouppoi]['name'].']'.navi
endfunction "}}}
function! s:make_menu_selgroup(grouplist,Markslistend) "{{{
  let menutext = ''
  for picked in a:grouplist
    let navi = substitute(s:make_navi(picked.name, a:Markslistend), '(TTL:\d\+)', '','g')
    let menutext .= " [".picked['name']."] ".navi."\n"
  endfor
  return menutext
endfunction "}}}
function! s:menu_select_group(firsttime,input,grouplist) "{{{
  if a:firsttime
    let input = substitute(a:input,'\s','\\\&.*','g')
    return filter(a:grouplist, 'v:val.name =~''^'.input.'''')
  else
    let input = substitute(substitute(a:input,'\s','\\\&.*','g'),'^','.*','')
    return filter(a:grouplist, 'v:val.name =~'''.input.'''')
  endif
endfunction "}}}
"mh ml
function! s:Cycle_group(ascending) "{{{
  let s:chk_continue = 'cycle_group'
  let markgroupsend = len(g:markgroups)-1
  let s:grouppoi = lclib#cycle_poi(a:ascending, s:grouppoi, markgroupsend)

  let crrlnum = line('.')
  let crrbufnr = bufnr('%')
  try
    call s:shiftgroup(crrlnum,crrbufnr)
  catch /Signage:.\{-}not.\{-}/
  endtry

  redraw|echo ''
  let navi = s:make_navi('', -1)
  let showattach = s:markslistpoi==-1 ? '' : s:markslist[s:markslistpoi]['attach']
  echo 'Signage: Set group at ['.g:markgroups[s:grouppoi]['name'].']'.navi.' '.showattach
endfunction "}}}
"mo
let s:signage_bufonly = 0
silent let s:save_SignColumn = 'hi '.lclib#gethighlight('SignColumn')
function! s:Crrbuf_only() "{{{
  silent let crrsignlist = lclib#lnum_id_of_sign(bufnr('%'))

  if empty(crrsignlist)
    if s:signage_bufonly
      call s:neutralizeSignColumn()
    else
      return
    endif
  else
    let s:signage_bufonly = !s:signage_bufonly
  endif

  if s:signage_bufonly
    silent! let s:save_SignColumn = 'hi '.lclib#gethighlight('SignColumn')
    silent exe 'hi SignColumn guibg=lightcyan guifg=red gui=underline ctermbg=cyan'
  else
    call s:neutralizeSignColumn()
  endif
endfunction "}}}
function! s:neutralizeSignColumn() "{{{
  let s:signage_bufonly = 0
  hi clear SignColumn
  silent exe s:save_SignColumn
endfunction "}}}
":SignageFindInvalidGroups
function! s:Find_invalidgroups(rename) "{{{
  let groupnamespat = ''
  for pickedgroup in g:markgroups
    let groupnamespat .= substitute(pickedgroup['name'],'.\+','\\<\0\\>\\|','')
  endfor
  let groupnamespat = substitute(groupnamespat, '\\|$', '','')

  let invalidgroups = []
  for picked in s:markslist
    if picked.group !~ groupnamespat
      call add(invalidgroups, picked.group)
    endif
  endfor

  if empty(invalidgroups)
    return
  endif
  echo 'SignageFindInvalidGroups: '.substitute('['.join(invalidgroups,'] [').']',  '[]','','g')
  if !a:rename
    return
  endif

  for invalidgroupname in invalidgroups
    let groupsclone = copy(g:markgroups)
    let firsttime = 1
    while len(groupsclone) > 1
      echo "Signage: What do you want to rename [".invalidgroupname."] to?\n"
      let menu = s:make_menu_selgroup(groupsclone,-1)
      let input = input(menu)
      if input == ''
        break
      endif
      let groupsclone = s:menu_select_group(firsttime,input,groupsclone)
      let firsttime = 0
      redraw|echo ''
    endwhile
    if input == ''
      continue
    endif
    if !empty(groupsclone)
      let idx = index(g:markgroups,groupsclone[0])
      cal s:rename_invalidgroup(invalidgroupname, groupsclone[0].name, idx)
      echo '['.invalidgroupname.'] is renamed to ['.groupsclone[0].name.'].'
    endif
  endfor
endfunction "}}}
function! s:rename_invalidgroup(invalidgroupname, renamedgroupname, idx) "{{{
  for picked in s:markslist
    if picked.group == a:invalidgroupname
      let picked.group = a:renamedgroupname
      exe 'sign define '.g:markgroups[a:idx]['name'].' text='.g:markgroups[a:idx]['char'].' linehl='.g:markgroups[a:idx]['linehl'].' texthl='.g:markgroups[a:idx]['charhl']
      let sign_id = signage_port#make_signid(1,bufnr(picked.path), picked.pos[1])
      exe 'sign unplace '.sign_id
      exe 'sign place '.sign_id.' line='.picked['pos'][1].' name='.picked['group'].' file='.picked['path']
    endif
  endfor
endfunction "}}}
":SignageSetmark
function! s:Setmark(...) "{{{
  let crrinfo = signage_port#makecrrinfo(0)
  if empty(crrinfo)
    return
  endif
  let localgrouppoi = s:grouppoi

  if a:0
    let notfind = 1
    for picked in g:markgroups
      if picked.name == a:1
        let localgrouppoi = index(g:markgroups, picked)
        let crrinfo.group = a:1
        let notfind = 0
      endif
    endfor
    if notfind
      echo 'Signage: The name''s group '.a:1.' is not found.'
      return
    endif
  else
    let crrinfo.group = g:markgroups[s:grouppoi].name
  endif
  let crrbufnr = bufnr('%')

  call s:register(0,crrinfo,crrbufnr,localgrouppoi,1)
  call s:show_registered(crrinfo.group, localgrouppoi)
endfunction "}}}


let s:unitesrc_signage = {
      \'name': 'signage',
      \'description': 'signageのmark一覧',
      \}
function! s:unitesrc_signage.gather_candidates(args, context) "{{{
  let candidates = []
  for picked in s:markslist
    let contents ={}
    let contents.word = printf("%41s (L:%5d) %-8s %s",
          \picked.path[-40:], picked.pos[1], '['.picked.group.']', picked.ctx
          \)
    if picked.attach != ''
      let contents.word .= "\nAttach: ".picked.attach
    endif
    let contents.kind = 'jump_list'
    let contents.action__path = picked.path
    let contents.action__line = picked.pos[1]
    let contents.action__col = picked.pos[2]
    let contents.is_multiline = 1
    call add(candidates,contents)
  endfor
  return candidates
endfunction "}}}
if exists('*unite#define_source')
  call unite#define_source(s:unitesrc_signage)
endif
unlet s:unitesrc_signage

let &cpo = s:save_cpo
unlet s:save_cpo






"TODO
"mu 最後に置いたsignを消してcrrposに新たに置く（移動させる）
"limit属性 この数以上のマークは存在できない。越えたときは古いマークが削除
"添付メッセージをgrep
"ビジュアル選択行を一気にsignする
"invalidgroupsを正常化したとき(rename)、現在あるsignと場所が被ってしまったら問題が起きるのではないかという疑惑
"同じ行に複数のマークがある場合、片側のmarkdel時にsignは両方削除されるのでsignし直す必要性
"同じ行に複数のマークが何らかの原因で付けられた場合、終了時にエラーを吐くのでバッティング時は後のマークを優先し先のマークを削除する
"現在バッファ内のsignを最適化（signされてないところはsignし直す。markとsignのズレを是正する）コマンドの必要性
"同じ行に複数signすると同一signIDが振られてしまう問題。→head番号をgroupidx+1にする？

