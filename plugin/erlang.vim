if exists('g:loaded_erlang')
    finish
endif
let g:loaded_erlang = 1

if !exists('g:erlang_erlc')
    let g:erlang_erlc = 'erlc'
endif

if !exists('g:erlang_rebar')
    let g:erlang_rebar = 'rebar'
endif

if !exists('g:erlang_dialyzer')
    let g:erlang_dialyzer = 'dialyzer'
endif

if !exists('g:erlang_ct_run')
    let g:erlang_ct_run = 'ct_run'
endif

if !exists('g:erlang_ct_run_opts')
    let g:erlang_ct_run_opts = '-noshell -ct_hooks cth_vimerl []'
endif

if !exists('g:erlang_tools_qf_mode')
    let g:erlang_tools_qf_mode = 'c'
endif

if !exists('g:erlang_no_commands')
    let g:erlang_no_commands = 0
endif

function Erlc(...)
    let opts = call (function('ErlcOpts'), a:000)
    if empty(opts)
        let cmd = g:erlang_erlc
    else
        let cmd = g:erlang_erlc . ' ' . opts
    endif
    echo cmd
    let output = system(cmd)
    echo output
    return ErlcParseOutput(output)
endfunction

function ErlcOpts(...)
    return ErlangToolOpts('erlang_erlc_opts', a:000)
endfunction

function ErlcParseOutput(output)
    if type(a:output) == 1
        let output = split(a:output, "\n")
        return ErlcParseOutput(output)
    else
        let qf_list = []
        for line in a:output
            let qf_item = ErlcParseLine(line)
            if !empty(qf_item)
                call add(qf_list, qf_item)
            endif
        endfor
        if !empty(qf_list)
            call setqflist(qf_list, g:erlang_tools_qf_mode)
            return 1
        else
            return 0
        endif
    endif
endfunction

function ErlcParseLine(line)
    " match 'filename:lnum: text' or 'filename:lnum: typename: text'
    let pattern = '^\(\f\+\):\(\d\+\):\s\=\(\(\(\u\)\a*\):\)\=\s\+\(.*\)$'
    let list = matchlist(a:line, pattern)
    if !empty(list)
        let qf_item = {'filename':list[1],'lnum':list[2],'text':list[6]}
        if empty(list[3])
            let qf_item['typename'] = 'Error'
            let qf_item['type'] = 'E'
        else
            let qf_item['typename'] = list[4]
            let qf_item['type'] = list[5]
        endif
        return qf_item
    else
        return {}
    endif
endfunction

function ErlcParseFile(filename)
    let bufnumber = bufnr(a:filename)
    if bufnumber == -1
        try
            let output = readfile(a:filename)
        catch /E484:/
            echo "No such file" a:filename
            return 2
        endtry
        return ErlcParseOutput(output)
    else
        return ErlcParseBuffer(bufnumber)
    endif
endfunction

function ErlcParseBuffer(...)
    if a:0 == 0
        let output = getline(1, '$')
        return ErlcParseOutput(output)
    elseif bufnr('%') == a:1
        return ErlcParseBuffer()
    else
        let currentbufnr = bufnr('%')
        silent execute "buffer" a:1
        let result = ErlcParseBuffer()
        silent execute "buffer" currentbufnr
        return result
    endif
endfunction

function Rebar(...)
    let opts = call (function('RebarOpts'), a:000)
    if empty(opts)
        let cmd = g:erlang_rebar
    else
        let cmd = g:erlang_rebar . ' ' . opts
    endif
    echo cmd
    let output = system(cmd)
    echo output
    return RebarParseOutput(output)
endfunction

function RebarParseOutput(output)
    if type(a:output) == 1
        let output = split(a:output, "\n")
        return RebarParseOutput(output)
    else
        let rebarcmd = ''
        let qf_list = []
        let qf_item = {}
        for line in a:output
            let list = matchlist(line,'^==> \(\a\w*\|''[^'']*''\) (\(\a\+\))\s*$')
            if !empty(list)
                let rebarcmd = list[2]
            endif
            if rebarcmd == 'compile'
                let qf_item = ErlcParseLine(line)
                if !empty(qf_item)
                    call add(qf_list, qf_item)
                endif
            endif
        endfor
        if !empty(qf_list)
            call setqflist(qf_list, g:erlang_tools_qf_mode)
            return 1
        else
            return 0
        endif
    endif
endfunction

function RebarOpts(...)
    return ErlangToolOpts('erlang_rebar_opts', a:000)
endfunction

function Dialyzer(...)
    let opts = call (function('DialyzerOpts'), a:000)
    if empty(opts)
        let cmd = g:erlang_dialyzer
    else
        let cmd = g:erlang_dialyzer . ' '. opts
    endif
    echo cmd
    let output = system(cmd)
    echo output
    return DialyzerParseOutput(output)
endfunction

function DialyzerOpts(...)
    return ErlangToolOpts('erlang_dialyzer_opts', a:000)
endfunction

function DialyzerParseOutput(output)
    if type(a:output) == 1
        let output = split(a:output, "\n")
        return DialyzerParseOutput(output)
    else
        let result = ErlcParseOutput(a:output)
        if result == 0
            let outputfile = ''
            let pat = '^\s*Check output file `\(\f\+\)'' for details\s*$'
            for line in a:output
                let list = matchlist(line, pat)
                if !empty(list)
                    let outputfile = list[1]
                    break
                endif
            endfor
            if !empty(outputfile)
                return DialyzerParseFile(outputfile)
            else
                return result
            endif
        else
            return result
        endif
    endif
endfunction

function DialyzerParseFile(filename)
    return ErlcParseFile(a:filename)
endfunction


function DialyzerParseBuffer(...)
    return call (function('ErlcParseBuffer'), a:000)
endfunction


function CTRun(...)
    let opts = call (function('CTRunOpts'), a:000)
    if empty(opts)
        let cmd = g:erlang_ct_run
    else
        let cmd = g:erlang_ct_run . ' ' . opts
    endif
    echo cmd
    let output = system(cmd)
    echo output
    return CTRunParseOutput(output)
endfunction

function CTRunOpts(...)
    return ErlangToolOpts('erlang_ct_run_opts', a:000)
endfunction

function CTRunParseOutput(output)
    if type(a:output) == 1
        let output = split(a:output, "\n")
        return CTRunParseOutput(output)
    elseif !empty(matchstr(a:output[0],'^Logging to "\(.\+\)"$'))
        return ErlcParseOutput(a:output)
    else
        let logfile = ''
        for line in a:output
            let list = matchlist(line, '^CWD set to: "\(.\+\)"$')
            if !empty(list)
                let logfile = list[1] . '/vimerl.log'
                break
            endif
        endfor
        if !empty(logfile)
            return ErlcParseFile(logfile)
        else
            echo "No vimerl.log"
            return 2
        endif
    endif
endfunction

function CTRunParseFile(filename)
    let bufnumber = bufnr(a:filename)
    if bufnumber == -1
        try
            let output = readfile(a:filename)
        catch /E484:/
            echo "No such file" a:filename
            return 2
        endtry
        return CTRunParseOutput(output)
    else
        return CTRunParseBuffer(bufnumber)
    endif
endfunction

function CTRunParseBuffer(...)
    if a:0 == 0
        let output = getline(1, '$')
        return CTRunParseOutput(output)
    elseif bufnr('%') == a:1
        return CTRunParseBuffer()
    else
        let currentbufnr = bufnr('%')
        silent execute "buffer" a:1
        let result = CTRunParseBuffer()
        silent execute "buffer" currentbufnr
        return result
    endif
endfunction


function ErlangToolOpts(varname, opts)
    if exists('b:'.a:varname)
        execute 'let defaultopts = b:'.a:varname
    elseif exists('g:'.a:varname)
        execute 'let defaultopts = g:'.a:varname
    endif
    if exists('defaultopts') && !empty(defaultopts)
        return join([defaultopts] + a:opts, ' ')
    else
        return join(a:opts, ' ')
    endif
endfunction


if g:erlang_no_commands == 0
    command -nargs=* Erlc call Erlc(<f-args>)
    command -nargs=* ErlcOpts echo ErlcOpts(<f-args>)
    command -nargs=* Rebar call Rebar(<f-args>)
    command -nargs=* RebarOpts echo RebarOpts(<f-args>)
    command -nargs=* Dialyzer call Dialyzer(<f-args>)
    command -nargs=* DialyzerOpts echo DialyzerOpts(<f-args>)
    command -nargs=* CTRun call CTRun(<f-args>)
    command -nargs=* CTRunOpts echo CTRunOpts(<f-args>)
endif
