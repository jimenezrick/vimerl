" Vim plugin file
" Language: Erlang
" Author:   Ricardo Catalinas Jiménez <jimenezrick@gmail.com>
" License:  GNU GPL version 3
" Version:  2011/09/10

if exists('g:loaded_erlang_skel') || v:version < 700 || &compatible
	finish
else
	let g:loaded_erlang_skel = 1
endif

if !exists('g:erlang_skel_replace')
	let g:erlang_skel_replace = 1
endif

let s:skels_dir = expand('<sfile>:p:h') . '/erlang_skels'

function s:LoadSkeleton(skel_name)
	if g:erlang_skel_replace
		%delete
	else
		let current_line = line('.')
		call append(line('$'), '')
		normal G
	endif
	if exists('g:erlang_skel_header')
		execute 'read' s:skels_dir . '/' . 'header'
		for [name, value] in items(g:erlang_skel_header)
			call s:SubstituteField(name, value)
		endfor
		if !has_key(g:erlang_skel_header, 'year')
			call s:SubstituteField('year', strftime('%Y'))
		endif
		call append(line('$'), '')
		normal G
	endif
	execute 'read' s:skels_dir . '/' . a:skel_name
	call s:SubstituteField('modulename', expand('%:t:r'))
	if g:erlang_skel_replace
		normal gg
		delete
	else
		call cursor(current_line, 1)
	endif
endfunction

function s:SubstituteField(name, value)
	execute '%substitute/\$' . toupper(a:name) . '/' . a:value . '/'
endfunction

command ErlangApplication silent call s:LoadSkeleton('application')
command ErlangSupervisor  silent call s:LoadSkeleton('supervisor')
command ErlangGenServer   silent call s:LoadSkeleton('gen_server')
command ErlangGenFsm      silent call s:LoadSkeleton('gen_fsm')
command ErlangGenEvent    silent call s:LoadSkeleton('gen_event')
