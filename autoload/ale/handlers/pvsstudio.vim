" Author: YuanYuan Chen <cyyever@outlook.com>
" Description: PVS Studio linter for C/C++ files

call ale#Set('pvs_studio_analyzer_executable', 'pvs-studio-analyzer')
call ale#Set('pvs_studio_analyzer_options', '')
call ale#Set('pvs_studio_plog_converter_executable', 'plog-converter')
call ale#Set('pvs_studio_plog_converter_options', '')

function! ale#handlers#pvsstudio#GetCdCommand(buffer) abort
    let [l:dir, l:json_path] = ale#c#FindCompileCommands(a:buffer)
    let l:cd_command = !empty(l:dir) ? ale#path#CdString(l:dir) : ''

    return l:cd_command
endfunction

function! ale#handlers#pvsstudio#GetExecutable(buffer) abort
    return ale#Var(a:buffer, 'pvs_studio_analyzer_executable')
endfunction

function! ale#handlers#pvsstudio#GetCommand(buffer) abort
    " Try to find compilation database to link automatically
	let l:build_dir = ale#c#GetBuildDirectory(a:buffer)
    if empty(l:build_dir)
      return ''
    endif

    let l:cd_command = !empty(l:build_dir) ? ale#path#CdString(l:build_dir) : ''
    let l:analyzer_options = ale#Var(a:buffer, 'pvs_studio_analyzer_options')
    let l:plog_converter_options = ale#Var(a:buffer, 'pvs_studio_plog_converter_options')

    return l:cd_command
    \  .'%e analyze --incremental '.l:analyzer_options.' -j5 -o ./pvs-studio.log && plog-converter -t tasklist '.l:plog_converter_options.' -o ./pvs-studio-report.txt ./pvs-studio.log && cat ./pvs-studio-report.txt'
endfunction

function! ale#handlers#pvsstudio#HandlePVSStudioFormat(buffer, lines) abort
    " Look for lines like the following.
    "
    " www.viva64.com/en/w      1       err     Help: The documentation for all analyzer warnings is available here: https://www.viva64.com/en/w/.
    let l:pattern = '\v^([^ ]+)\s+(\d+)\s*([a-z]+)\s*(.+)$'
    let l:output = []

    for l:match in ale#util#GetMatches(a:lines, l:pattern)
        if ale#path#IsBufferPath(a:buffer, l:match[1])
            call add(l:output, {
            \   'lnum': str2nr(l:match[2]),
            \   'type': l:match[3] is# 'err' ? 'E' : (l:match[3] is# 'warn' ? 'W' : 'I'),
            \   'text': l:match[4],
            \})
        endif
    endfor

    return l:output
endfunction

" Define the pvsstudio linter for a given filetype.
function! ale#handlers#pvsstudio#DefineLinter(filetype) abort
    call ale#linter#Define(a:filetype, {
    \   'name': 'pvsstudio',
    \   'executable': function('ale#handlers#pvsstudio#GetExecutable'),
    \   'command': function('ale#handlers#pvsstudio#GetCommand'),
    \   'output_stream': 'stdout',
    \   'callback': 'ale#handlers#pvsstudio#HandlePVSStudioFormat',
    \})
endfunction
