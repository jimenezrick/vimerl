" Vim ftplugin file
" Language:     Erlang
" Author:       Oscar Hellström <oscar@oscarh.net>
" Contributors: Ricardo Catalinas Jiménez <jimenezrick@gmail.com>
"               Eduardo Lopez (http://github.com/tapichu)
"               Markus Mroch <mmroch@mr-pi.de> (https://mr-pi.de)
" License:      Vim license
" Version:      2013-11-15

if exists('b:did_ftplugin')
	finish
else
	let b:did_ftplugin = 1
endif

if exists('s:did_function_definitions')
	call s:SetErlangOptions()
	finish
else
	let s:did_function_definitions = 1
endif

if !exists('g:erlang_keywordprg')
	let g:erlang_keywordprg = 'erl -man'
endif

if !exists('g:erlang_folding')
	let g:erlang_folding = 0
endif

"comment block folding options
if !exists('g:erlang_folding_comments')
	let g:erlang_folding_comments = 0
endif


let s:erlang_fun_begin = '^\(\a\w*\|[''][^'']*['']\)(.*$'
let s:erlang_fun_end   = '^[^%]*\.\s*\(%.*\)\?$'

let s:erlang_commentBlock = '^%%[^%]*$'

function s:SetErlangOptions()
	compiler erlang
	if version >= 700
		setlocal omnifunc=erlang_complete#Complete
	endif

	if g:erlang_folding
		setlocal foldmethod=expr
		setlocal foldexpr=GetErlangFold(v:lnum)
		setlocal foldtext=ErlangFoldText()
	endif

	setlocal comments=:%%%,:%%,:%
	setlocal commentstring=%%s
	setlocal formatoptions+=ro
	setlocal suffixesadd=.erl
	let libs = substitute(system('which erl'), '/bin/erl', '/lib/erlang/lib/**/src/', '')
	execute 'setlocal path+=' . libs
	let &l:keywordprg = g:erlang_keywordprg
endfunction

function GetErlangFold(lnum)
	let lnum = a:lnum
	let line = getline(lnum)

	"function folding
	if line =~ s:erlang_fun_end
		return '<1'
	elseif line =~ s:erlang_fun_begin && foldlevel(lnum - 1) == 1
		return '1'
	elseif line =~ s:erlang_fun_begin
		return '>1'
	endif

	"comment block folding
	if g:erlang_folding_comments
		if line =~ s:erlang_commentBlock && getline(lnum+1) =~ s:erlang_commentBlock
			return '1'
		elseif getline(lnum-1) =~ s:erlang_commentBlock
			return '<1'
		endif
	endif

	return '='
endfunction

function ErlangFoldText()
	let lnum = v:foldstart
	let line = getline(v:foldstart)
	let foldlen = v:foldend - v:foldstart + 1
	if line =~ s:erlang_commentBlock
		let i=0
		while i < foldlen
			let cline = getline(lnum+i)
			if cline =~ ".*@doc .*"
				return v:folddashes . "DOC: " . substitute(cline, "[^@]*@doc ", '', '')
			elseif cline =~ "% [^@]"
				return v:folddashes . "DOC: " . substitute(cline, "[% \t]*", '', '')
			endif
			let i = i + 1 
		endwhile
	else
		let lines   = ' ' . foldlen . ' lines: ' . substitute(line, "[ \t]*", '', '')
		if foldlen < 10
			let lines = ' ' . lines
		endif
		let retval = '+' . v:folddashes . lines
	endif

	return retval
endfunction

call s:SetErlangOptions()
