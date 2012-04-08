

"マーク(crrinfo)の作成
function! altmarks_port#makecrrinfo(attach) "{{{
  let attach = ''
  if a:attach "コメント付きでマークするとき
    if a:attach == 1
      let attach = input('AltMarksInput: ')
    else
      let attach = input('AltMarksAppend: ')
    endif
    if attach != ''
      "let attach = "\n".attach
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
        \ 'attach':attach,
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
function! altmarks_port#replay_mark(crrpath,crrpos,newpath,newpos) "{{{1
  let return = 0
  if a:crrpath != a:newpath
    silent exe 'edit '. a:newpath
    let return = 1
  endif
  if a:crrpos[1] != a:newpos[1] && a:crrpos[1] != line('$')
    call setpos('.', a:newpos)
    normal! zv
    let return = 1
  endif
  return return
endfunction "}}}1
"signで使うhighlight定義
function! altmarks_port#def_signhl() "{{{
  hi linehl_red  guibg=firebrick4 ctermbg=darkred
  hi linehl_green  guibg=darkslategray4 ctermbg=darkgreen
  hi linehl_blue  guibg=royalblue4 ctermbg=blue
  hi linehl_yellow  guibg=#888800 ctermbg=darkyellow
  hi linehl_purple  guibg=darkmagenta ctermbg=darkmagenta
  hi linehl_gray  guibg=dimgray ctermbg=gray
  hi linehl_orange  guibg=indianred3 ctermbg=darkred
  hi linehl_reverse  gui=reverse cterm=reverse
  hi linehl_standout  gui=standout cterm=standout

  hi texthl_red gui=bold guifg=white guibg=red
  hi texthl_green gui=bold guifg=white guibg=green
  hi texthl_blue gui=bold guifg=white guibg=blue
  hi texthl_yellow gui=bold guifg=black guibg=yellow
  hi texthl_purple gui=bold guifg=white guibg=purple
  hi texthl_gray gui=bold guifg=white guibg=gray30
  hi texthl_orange gui=bold guifg=blue guibg=orange
endfunction "}}}
"signIDを100300254のように生成(head,バッファ番,行番)
function! altmarks_port#make_signid(head,bufnr,lnum) "{{{
  return printf('%d%0.3d%0.5d', a:head, a:bufnr, a:lnum)
endfunction "}}}

