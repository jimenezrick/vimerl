" Vim omni completion file
" Language:     Erlang
" Author:       Oscar Hellström <oscar@oscarh.net>
" Contributors: kTT (http://github.com/kTT)
"               Ricardo Catalinas Jiménez <jimenezrick@gmail.com>
"               Eduardo Lopez (http://github.com/tapichu)
" License:      GNU GPL version 3
" Version:      2011/09/29

" Completion options
if !exists('g:erlang_completion_grep')
	let g:erlang_completion_grep = 'zgrep'
endif

if !exists('g:erlang_completion_display_doc')
	let g:erlang_completion_display_doc = 1
endif

" Completion program path
let s:erlang_complete_file = expand('<sfile>:p:h') . '/erlang_complete.erl'

" Man pages path
let s:erlang_man_path = system("grep ^ROOTDIR= $(which erl) | sed 's/^.*=//'")[:-2] . '/man'

" Modules cache used to speed up the completion
let s:modules_cache = {}

" Patterns for completions
let s:erlang_local_func_beg    = '\(\<[0-9A-Za-z_-]*\|\s*\)$'
let s:erlang_external_func_beg = '\<[0-9A-Za-z_-]\+:[0-9A-Za-z_-]*$'
let s:erlang_blank_line        = '^\s*\(%.*\)\?$'

" Main function for completion
function erlang_complete#Complete(findstart, base)
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
	" If it is a local module, try to compile it when the .beam
	" doesn't exist or is old
	if filereadable(a:module . '.erl')
		if !filereadable(a:module . '.beam') ||
				\ getftime(a:module . '.erl') > getftime(a:module . '.beam')
			if has_key(s:modules_cache, a:module)
				call remove(s:modules_cache, a:module)
			endif
			silent execute '!erlc' a:module . '.erl' '>/dev/null' '2>/dev/null'
			redraw!
		endif
	endif

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
	for element in sort(split(functions, '\n'))
		if match(element, a:base) == 0
			let function_name = matchstr(element, a:base . '\w*')
			let number_of_args = matchstr(element, '\d\+', len(function_name))
			let number_of_comma = max([number_of_args - 1, 0])
			let file_path = s:erlang_man_path . '/man?/' . a:module . '.*'
			let description = ''

			" Don't look man pages if the module is present in the current directory
			if g:erlang_completion_display_doc != 0 && !filereadable(a:module . '.beam')
				let system_command = g:erlang_completion_grep . ' -A 1 "\.B" ' . file_path .
						   \ ' | grep -Eo "\<' . function_name . '\>\((\[?\w+,\]? ){' .
						   \ number_of_comma . '}[^),]*\) -> .*"'
				let description = system(system_command)

				" Cutting some weird characters at the end with `[:-2]'
				" because grep doesn't support multilines, so we have to
				" filter first by `.B' and next by looking via function
				" name, if someone have a better idea, please change it
				let description = description[:-2]
			endif

			if description == ''
				" If function doesn't have a description e.g.
				" lists:rmerge, put rmerge/2 instead
				let description = element
			endif

			let field = {'word': function_name . '(', 'abbr': description,
				  \  'kind': 'f', 'dup': 1} " Allow duplicated functions
			call complete_add(field)

			" Populate the cache only when iterating over all the
			" module functions (i.e. no prefix for the completion)
			if a:base == ''
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
