" Vim compiler file
" Language:     Erlang
" Author:       Pawel 'kTT' Salata <rockplayer.pl@gmail.com>
" Contributors: Ricardo Catalinas Jiménez <jimenezrick@gmail.com>
" Version:      2011/12/14

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Copyright 2010 Pawel 'kTT' Salata
" Copyright 2011 Ricardo Catalinas Jiménez
"
" This file is part of Vimerl.
"
" Vimerl is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" Vimerl is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the-
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with Vimerl.  If not, see <http://www.gnu.org/licenses/>.
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists("current_compiler")
    finish
else
    let current_compiler = "erlang"
endif

let b:error_list     = {}
let b:is_showing_msg = 0
let b:next_sign_id   = 1

if exists(":CompilerSet") != 2
    command -nargs=* CompilerSet setlocal <args>
endif

if !exists("g:erlang_show_errors")
    let g:erlang_show_errors = 1
endif

" Only define functions and script scope variables once
if exists("*s:ShowErrors")
    finish
endif

let s:erlang_check_file = expand("<sfile>:p:h") . "/erlang_check.erl"
let s:autocmds_defined  = 0

sign define ErlangError   text=>> texthl=Error
sign define ErlangWarning text=>> texthl=Todo

command ErlangDisableShowErrors silent call s:DisableShowErrors()
command ErlangEnableShowErrors  silent call s:EnableShowErrors()

function s:ShowErrors()
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
    setlocal shellpipe&
    setlocal makeprg=make
endfunction

function s:ShowErrorMsg()
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

function s:ClearErrors()
    sign unplace *
    let b:error_list   = {}
    let b:next_sign_id = 1
    if b:is_showing_msg
        echo
        let b:is_showing_msg = 0
    endif
endfunction

function s:EnableShowErrors()
    if !s:autocmds_defined
        autocmd BufWritePost *.erl call s:ShowErrors()
        autocmd CursorHold   *.erl call s:ShowErrorMsg()
        autocmd CursorMoved  *.erl call s:ShowErrorMsg()
        let s:autocmds_defined = 1
    endif
endfunction

function s:DisableShowErrors()
    sign unplace *
    autocmd! BufWritePost *.erl
    autocmd! CursorHold   *.erl
    autocmd! CursorMoved  *.erl
    let s:autocmds_defined = 0
endfunction

CompilerSet makeprg=make
CompilerSet errorformat=%W%f:%l:\ Warning:\ %m,%E%f:%l:\ %m

if g:erlang_show_errors
    call s:EnableShowErrors()
endif
