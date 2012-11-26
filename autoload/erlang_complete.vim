" Vim omni completion file
" Language:     Erlang
" Author:       Oscar Hellström <oscar@oscarh.net>
" Contributors: kTT (http://github.com/kTT)
"               Ricardo Catalinas Jiménez <jimenezrick@gmail.com>
"               Eduardo Lopez (http://github.com/tapichu)
" License:      Vim license
" Version:      2012/01/14

" Completion program path
let s:erlang_complete_file = expand('<sfile>:p:h') . '/erlang_complete.erl'

let s:erlang_complete_cache_file = expand('<sfile>:p:h') . '/erlang_index'
let s:erlang_cache_load = 0

if !exists('g:erlang_completion_cache')
	let g:erlang_completion_cache = 1
endif

" Modules cache used to speed up the completion
let s:modules_cache = {}

" Patterns for completions
let s:erlang_local_func_beg    = '\(\<[0-9A-Za-z_-]*\|\s*\)$'
let s:erlang_external_func_beg = '\<[0-9A-Za-z_-]\+:[0-9A-Za-z_-]*$'
let s:erlang_blank_line        = '^\s*\(%.*\)\?$'

" Main function for completion
function erlang_complete#Complete(findstart, base)
	if s:erlang_cache_load == 0
		call s:ErlangLoadCache(a:base)
		let s:erlang_cache_load = 1
	endif

	let lnum = line('.')
	let column = col('.')
	let line = strpart(getline('.'), 0, column - 1)

	" 1) Check if the char to the left of us are part of a function call
	"
	" Nothing interesting is written at the char just before the cursor
	" This means _anything_ could be started here
	" In this case, keyword completion should probably be used,
	" for now we'll only try and complete local functions.
	"
	" TODO: Examine if we can stare Identifiers end complete on them
	" Is this worth it? Is /completion/ of a "blank" wanted? Can we consider
	" `(' interesting and check if we are in a function call etc.?
	if line[column - 2] !~ '[0-9A-Za-z:_-]'
		if a:findstart
			return column
		else
			return s:ErlangFindLocalFunc(a:base)
		endif
	endif
	
	" 2) Function in external module
	if line =~ s:erlang_external_func_beg
		let delimiter = match(line, ':[0-9A-Za-z_-]*$') + 1
		if a:findstart
			return delimiter
		else
			let module = matchstr(line[:-2], '\<\k*\>$')
			return s:ErlangFindExternalFunc(module, a:base)
		endif
	endif

	" 3) Local function
	if line =~ s:erlang_local_func_beg
		let funcstart = match(line, ':\@<![0-9A-Za-z_-]*$')
		if a:findstart
			return funcstart
		else
			return s:ErlangFindLocalFunc(a:base)
		endif
	endif

	" 4) Unhandled situation
	if a:findstart
		return -1
	else
		return []
	endif
endfunction

" Find the next non-blank line
function s:ErlangFindNextNonBlank(lnum)
	let lnum = nextnonblank(a:lnum + 1)
	let line = getline(lnum)

	while line =~ s:erlang_blank_line && 0 != lnum
		let lnum = nextnonblank(lnum + 1)
		let line = getline(lnum)
	endwhile

	return lnum
endfunction

" Find external function names
function s:ErlangFindExternalFunc(module, base)
	" If the module is cached, load its functions
	if has_key(s:modules_cache, a:module)
		for field_cache in get(s:modules_cache, a:module)
			if match(field_cache.word, a:base) == 0
				call complete_add(field_cache)
			endif
		endfor

		return []
	endif

	let functions = system(s:erlang_complete_file . ' ' . a:module)
	for function_spec in split(functions, '\n')
		if match(function_spec, a:base) == 0
			let function_name = matchstr(function_spec, a:base . '\w*')
			let field = {'word': function_name . '(', 'abbr': function_spec,
				  \  'kind': 'f', 'dup': 1}
			call complete_add(field)

			" Populate the cache only when iterating over all the
			" module functions (i.e. no prefix for the completion)
			if g:erlang_completion_cache && a:base == ''
				if !has_key(s:modules_cache, a:module)
					let s:modules_cache[a:module] = [field]
				else
					let fields_cache = get(s:modules_cache, a:module)
					let s:modules_cache[a:module] = add(fields_cache, field)
				endif
			endif

			" The user entered some text, so stop the completion
			if complete_check()
				" The module couldn't be entirely cached
				if has_key(s:modules_cache, a:module)
					call remove(s:modules_cache, a:module)
				endif
				break
			endif
		endif
	endfor

	let func_lists = s:modules_cache[a:module]
	if len(func_lists) > 0
		let tmp_cache = {a:module : func_lists}
		" write cache to file
		exe "redir! >> " . s:erlang_complete_cache_file
		silent echon tmp_cache
		silent echon "\n"
		redir END
	endif

	return []
endfunction

" Find local function names
function s:ErlangFindLocalFunc(base)
	" Begin at line 1
	let lnum = s:ErlangFindNextNonBlank(1)

	if "" == a:base
		let base = '\w' " Used to match against word symbol
	else
		let base = a:base
	endif

	while 0 != lnum && !complete_check()
		let line = getline(lnum)
		let function_name = matchstr(line, '^' . base . '[0-9A-Za-z_-]\+(\@=')
		if function_name != ""
			call complete_add({'word': function_name, 'kind': 'f'})
		endif
		let lnum = s:ErlangFindNextNonBlank(lnum)
	endwhile

	return []
endfunction

function s:ErlangLoadCache(base)
	if filereadable(s:erlang_complete_cache_file)
		for line in readfile(s:erlang_complete_cache_file)
			let cache = eval(line)
			for key in keys(cache)
				" add module function list to the cache
				let function_list = get(cache, key)
				let s:modules_cache[key] = function_list
			endfor
		endfor
	endif

	return []
endfunction
