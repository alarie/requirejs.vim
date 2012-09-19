if exists('rjs_loaded')
    finish
endif
let rjs_loaded = 1


if !exists("g:require_js_config_file")
    let g:require_js_config_file = ''
endif

if !exists("g:require_base_url")
    let g:require_js_base_url = ''
endif

if !exists("g:require_js_paths")
    let g:require_js_paths = {}
endif





fun! RJS_OpenFile(file)
    let map = {}
    let file = ''
    " file conatains require or define
    
    " get the urlstring under the curser
    if empty(a:file)
        let file = s:RJS_GetFileNameFromString()
        if empty(file)
            let file = s:RJS_GetFileNameFromVariable(map)
            if empty(file)
                echom "No matching file found"
            endif
        endif
    else
        let file = a:file
    endif

    echo "Opening file:  " . file

    if !empty(file)
        call s:RJS_GetConfig()

        if match(file, '^text!') == -1
            call s:RJS_OpenJSFile(file)
        else
            let file = substitute(file, '^text!', '', '')
            call s:RJS_OpenTextFile(file)
        endif
    endif
endf


fun! s:RJS_GetFileNameFromString()
    try
        let a_save = @a
        let @a = ''
        normal! "ayi'
        if !empty(@a)
            return @a
        else
            normal! "ayi"
            if !empty(@a)
                return @a
            else 
                return ''
            endif
        endif
    finally
        let @a = a_save
    endtry
endf

fun! s:RJS_GetFileNameFromVariable(map)
    try
        let a_save = @a
        let @a = ''
        normal! "ayiw
        if !empty(@a)
            let var = @a
            if empty(a:map) 
                call s:RJS_LoadRequireList(a:map)
            endif
            if has_key(a:map, var) 
                return a:map[var]
            else
                echom "No file for " . var
            endif
        else
            return ''
        endif
    finally
        let @a = a_save
    endtry
endf

fun! s:RJS_LoadRequireList(map) 
    try
        let a_save = @a
        normal! ggVG"ay
        let file_contents = @a
        let define = matchstr(file_contents, 'define\s*(\s*\[\_.\{-}\]\s*,\s*function\s*(\_.\{-})')
        let files = s:RJS_Trim(split(matchstr(define, 'define\s*(\s*\[\zs\_.\{-}\ze\]'), ','))
        let vars = s:RJS_Trim(split(matchstr(define, 'function\s*(\zs\_.\{-}\ze)'), ','))
        let i = 0

        for file in files
            let var_name = get(vars, i)
            if  !empty(var_name)
                let a:map[var_name] = file
            endif
            let i += 1
        endfor
    finally
        let @a = a_save
    endtry
endf

fun! s:RJS_Trim(arr)
    let i = 0
    let arr = a:arr
    for entry in arr
        let arr[i] = substitute(substitute(entry, '^\_\s*[''"]*', '', ''), '[''"]*\_\s*$', '', '')
        let i += 1
    endfor
    return arr
endf


fun! s:RJS_GetConfig() 
    " find the config file
    if empty(g:require_js_config_file) || empty(g:require_js_base_url) || empty(g:require_js_paths)
        let js_dir = getcwd()
        let requirejs_configs = split(system("grep -lR 'requirejs.config' " . js_dir . "/* | grep -v .md", '\n'))
        " TODO determine which file is actuall the right one
        let g:require_js_config_file = requirejs_configs[0]

        let contents = system("cat " . g:require_js_config_file)
        let config = matchstr(contents, 'requirejs.config\_.\{-}});')

        if empty(config)
            throw "Config not found"
        endif

        let g:require_js_base_url = matchstr(config, 'baseUrl[''"]\?\s*:\s*\([''"]\)\zs.\{-}\ze\1')
        let paths_str = split(matchstr(config, 'paths[''"]\?\s*:\s*{\n\zs\_.\{-}\ze}'), '\n')
        " read and use the paths
        let g:require_js_paths = {}
        for i in paths_str
            let key = matchstr(i, '\s*\([''"]\?\)\zs.\{-}\ze\1\s')
            let val = matchstr(i, '\s*\([''"]\?\)' . key . '\1\s*:\s*\([''"]\)\zs.\{-}\ze\2')
            if !empty(key)
                let g:require_js_paths[key] = val
            endif
        endfor
    endif
endf



fun! s:RJS_OpenJSFile(file) 
    let js_file = a:file
    let path_keys = keys(g:require_js_paths)

    for k in path_keys 
        if match(js_file, '^' . k) != -1
            let js_file = substitute(g:require_js_paths[k] . '/' . substitute(js_file, '^' . k, '', ''), '/$', '', '')
        endif
    endfor

    " append prepend baseUrl and append .js to the file
    if match(js_file, '.js$') == -1
        let js_file = g:require_js_base_url . '/' . js_file . '.js'
    endif

    " check if file is readable and try to open it in new tab
    if (filereadable(js_file))
        exec ':tabe ' . js_file
    else
        echom "No such file: " . js_file
    endif
endf



fun! s:RJS_OpenTextFile(file) 
    let text_file = a:file

    let path_keys = keys(g:require_js_paths)
    let pattern = '^' . substitute(g:require_js_base_url, '[^/]\+', "[^/]\\\\+", 'g') . '/'
    for k in path_keys 
        if match(text_file, '^' . k) != -1
            let text_file = substitute(g:require_js_paths[k] . substitute(text_file, '^' . k, '', ''), '/$', '', '')
        endif
    endfor

    let text_file = substitute(text_file, pattern, '', '')

    " check if file is readable and try to open it in new tab
    if (filereadable(text_file))
        exec ':tabe ' . text_file
    else
        echom "No such file: " . text_file
    endif
endf




nmap <silent> gt :call RJS_OpenFile('')<CR> 
