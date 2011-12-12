" Vim compiler file
" Language:     Erlang
" Author:       Pawel 'kTT' Salata <rockplayer.pl@gmail.com>
" Contributors: Ricardo Catalinas Jiménez <jimenezrick@gmail.com>
" Version:      2011/09/23

if exists("current_compiler")
    finish
else
    let current_compiler = "erlang"
endif

if exists(":CompilerSet") != 2
    command -nargs=* CompilerSet setlocal <args>
endif

if !exists("g:erlang_show_errors")
    let g:erlang_show_errors = 1
endif

let s:erlang_check_file = expand("<sfile>:p:h") . "/erlang_check.erl"
let b:error_list        = {}
let b:is_showing_msg    = 0
let b:next_sign_id      = 1

sign define ErlangError   text=>> texthl=Error
sign define ErlangWarning text=>> texthl=Todo

command! ErlangDisableShowErrors silent call s:DisableShowErrors()
command! ErlangEnableShowErrors  silent call s:EnableShowErrors()

function! s:ShowErrors()
    setlocal shellpipe=>
    if match(getline(1), "#!.*escript") != -1
        setlocal makeprg=escript\ -s\ %
    else
        execute "setlocal makeprg=" . s:erlang_check_file . "\\ \%"
    endif
    silent make!
    call s:ClearErrors()
    for error in getqflist()
        let item         = {}
        let item["lnum"] = error.lnum
        let item["text"] = error.text
        let b:error_list[error.lnum] = item
        let type = error.type == "W" ? "ErlangWarning" : "ErlangError"
        execute "sign place" b:next_sign_id "line=" . item.lnum "name=" . type "file=" . expand("%:p")
        let b:next_sign_id += 1
    endfor
    call s:ShowErrorMsg()
    setlocal shellpipe&
    setlocal makeprg=make
endfunction

function! s:ShowErrorMsg()
    let pos = getpos(".")
    if has_key(b:error_list, pos[1])
        let item = get(b:error_list, pos[1])
        echo item.text
        let b:is_showing_msg = 1
    else
        if b:is_showing_msg
            echo
            let b:is_showing_msg = 0
        endif
    endif
endf

function! s:ClearErrors()
    for id in range(1, b:next_sign_id - 1)
        execute "sign unplace" id "file=" . expand("%:p")
    endfor
    let b:error_list = {}
    if b:is_showing_msg
        echo
        let b:is_showing_msg = 0
    endif
endfunction

function! s:EnableShowErrors()
    if !exists("s:erlang_autocommands_set")
        let s:erlang_autocommands_set = 1
    autocmd BufWritePost *.erl call s:ShowErrors()
    autocmd CursorHold   *.erl call s:ShowErrorMsg()
    autocmd CursorMoved  *.erl call s:ShowErrorMsg()
endfunction

function! s:DisableShowErrors()
    unlet s:erlang_autocommands_set
    sign unplace *
    autocmd! BufWritePost *.erl
    autocmd! CursorHold   *.erl
    autocmd! CursorMoved  *.erl
endfunction

CompilerSet makeprg=make
CompilerSet errorformat=%W%f:%l:\ Warning:\ %m,%E%f:%l:\ %m

if g:erlang_show_errors
    call s:EnableShowErrors()
endif
