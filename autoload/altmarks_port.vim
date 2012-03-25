

"マーク(crrinfo)の作成
function! altmarks_port#makecrrinfo(attatch) "{{{
  let attatch = ''
  if a:attatch "コメント付きでマークするとき
    if a:attatch = 1
      let attatch = input('AltMarksInput: ')
    else
      let attatch = input('AltMarksAppend: ')
    endif
    if attatch != ''
      "let attatch = "\n".attatch
    else
      return {}
    endif
  endif

  let crrpath = expand('%:p')
  if crrpath == ''
    echoerr 'AltMarks: No name buffer cannot mark.'
    return {}
  endif

  let crrinfo = {
        \ 'path':crrpath,
        \ 'pos':getpos('.'),
        \ 'ctx':altmarks_port#Get_ctx(),
        \ 'attatch':attatch,
        \ 'protect': '',
        \ }
  return crrinfo
endfunction "}}}
"マーク当時の行の文字列を取り込む
function! altmarks_port#Get_ctx()  "{{{1
  let col = col('.')
  let start = col-30 < 0 ? 0 :col-20
  return lclib#rm_multibyte_garbage(getline('.')[(start):col+30])
endfun "}}}1
"path posが現在地と新しい情報で食い違っていたら新しいposにカーソルセットしてreturn=1を返す
function! altmarks_port#replay_mark(curpath,curpos,newpath,newpos) "{{{1
  let return = 0
  if a:curpath != a:newpath
    silent exe 'edit '. a:newpath
    let return = 1
  endif
  if a:curpos[1] != a:newpos[1] && a:curpos[1] != line('$')
    call setpos('.', a:newpos)
    normal! zv
    let return = 1
  endif
  return return
endfunction "}}}1
"idxポインタをサイクルさせる（末尾でループ）
function! altmarks_port#cycle_poi(ascending, pointer, idxend) "{{{
  let idxpointer = a:ascending ? a:pointer-1 : a:pointer+1
  if idxpointer < 0
    let idxpointer = a:idxend
  elseif idxpointer > a:idxend
    let idxpointer = 0
  endif
  return idxpointer
endfunction "}}}
"signで使うhl定義
function! altmarks_port#def_signhl() "{{{
  hi linehl_blue  guibg=royalblue4 ctermbg=blue
  hi linehl_green  guibg=darkslategray4 ctermbg=darkgreen
  hi linehl_red  guibg=firebrick4 ctermbg=darkred
  hi linehl_purple  guibg=darkmagenta ctermbg=darkmagenta

  hi texthl_red gui=bold guifg=white guibg=red
  hi texthl_green gui=bold guifg=white guibg=green
  hi texthl_blue gui=bold guifg=white guibg=blue
  hi texthl_yellow gui=bold guifg=black guibg=yellow
  hi texthl_purple gui=bold guifg=white guibg=purple
endfunction "}}}
"idxポインタを次のグループまでサイクルさせる（末尾でループ）
function! altmarks_port#cycle_pointer_in_group() "{{{
endfunction "}}}

