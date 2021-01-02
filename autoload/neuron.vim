let g:_neuron_queued_function = []
let g:_neuron_cache_add_titles = 1

func! neuron#add_virtual_titles()
	if !exists("g:_neuron_zettels_by_id")
		return
	end
	if !exists('*nvim_buf_set_virtual_text')
		return
	endif

	let l:ns = nvim_create_namespace('neuron')
	call nvim_buf_clear_namespace(0, l:ns, 0, -1)
	let l:re_neuron_link = '\[\[\[\?\([0-9a-zA-Z_-]\+\)\(?cf\)\?\]\]\]\?'
	let l:lnum = -1
	for line in getline(1, "$")
		let l:lnum += 1
		let l:zettel_id = util#get_zettel_in_line(line)
		if empty(l:zettel_id)
			continue
		endif
		let l:title = g:_neuron_zettels_titles_list[l:zettel_id]
		" TODO: Use
		" nvim_buf_set_extmark({buffer}, {ns_id}, {id}, {line}, {col}, {opts})
		" function instead of nvim_buf_set_virtual_text. Check this link for
		" help https://github.com/neovim/neovim/blob/e628a05b51d4620e91662f857d29f1ac8fc67862/runtime/doc/api.txt#L1935-L1955
		call nvim_buf_set_virtual_text(0, l:ns, l:lnum, [[l:title, 'TabLineFill']], {})
	endfor

	if g:neuron_inline_backlinks == 0
		return
	endif

	" on gzn this key will not exist
	let l:backn = len(get(g:_neuron_backlinks, util#current_zettel(), []))
	if l:backn == 1
		let l:backtext = "1 backlink"
	else
		let l:backtext = l:backn." backlinks"
	endif
	call nvim_buf_set_virtual_text(0, l:ns, 0, [[l:backtext, "DiffChange"]], {})
endf

func! neuron#insert_reducer_folgezettel(lines)
	let l:results = []
	for line in a:lines
		let l:result = '[[[' . split(line, ":")[0] . ']]]'
		call add(l:results, l:result)
	endfor
	return join(l:results, ',')
endfunc

func! neuron#insert_reducer(lines)
	let l:results = []
	for line in a:lines
		let l:result = '[[' . split(line, ":")[0] . ']]'
		call add(l:results, l:result)
	endfor
	return join(l:results, ',')
endfunc

func! neuron#insert_zettel_complete(as_folgezettel)
	if !exists("g:_neuron_zettels_by_id")
		echom "Waiting until cache is populated..."
		let g:_neuron_queued_function = ['neuron#insert_zettel_select', [a:as_folgezettel]]
		return
	end

	if a:as_folgezettel
		let l:reducer_to_use = 'neuron#insert_reducer_folgezettel'
	else
		let l:reducer_to_use = 'neuron#insert_reducer'
	endif

	return call('fzf#vim#complete', [fzf#wrap({
		\ 'options': util#get_fzf_options('Select zettel: '),
		\ 'source': g:_neuron_zettels_search_list,
		\ 'reducer': function(l:reducer_to_use)
	\ }, g:neuron_fullscreen_search)])
endfunc

func! neuron#insert_zettel_select(as_folgezettel)
	if !exists("g:_neuron_zettels_by_id")
		echo "Waiting until cache is populated..."
		let g:_neuron_queued_function = ['neuron#insert_zettel_select', [a:as_folgezettel]]
		return
	end

	if a:as_folgezettel
		let l:sink_to_use = 'util#insert_shrink_fzf_folgezettel'
	else
		let l:sink_to_use = 'util#insert_shrink_fzf'
	endif

	call fzf#run(fzf#wrap({
		\ 'options': util#get_fzf_options(),
		\ 'source': g:_neuron_zettels_search_list,
		\ 'sink': function(l:sink_to_use),
	\ }, g:neuron_fullscreen_search))
endf

func! neuron#search_content(use_cursor)
	let l:query = ""
	if a:use_cursor
		let l:query = expand("<cword>")
	endif
	call fzf#vim#ag(l:query, fzf#vim#with_preview({'dir': g:neuron_dir, 'options': '--exact'}), g:neuron_fullscreen_search)
endf

func! neuron#edit_zettel_select()
	if !exists("g:_neuron_zettels_by_id")
		echo "Waiting until cache is populated..."
		let g:_neuron_queued_function = ['neuron#edit_zettel_select', []]
		return
	end

	call fzf#run(fzf#wrap({
		\ 'options': util#get_fzf_options(),
		\ 'source': g:_neuron_zettels_search_list,
		\ 'sink': function('util#edit_shrink_fzf'),
	\ }, g:neuron_fullscreen_search))
endf

func! neuron#edit_zettel_backlink()
	if !exists("g:_neuron_zettels_by_id")
		echo "Waiting until cache is populated..."
		let g:_neuron_queued_function = ['neuron#edit_zettel_backlink', []]
		return
	end

	let l:current_zettel = util#current_zettel()

	let l:list = []
	for id in g:_neuron_backlinks[l:current_zettel]
		call add(l:list, id.":".g:_neuron_zettels_titles_list[id])
	endfor

	let l:options = util#get_fzf_options()
	let l:options = l:options + ["--header", "Backlinks to <".l:current_zettel.">"]
	let l:options = l:options + ["--reverse"]
	let l:options = l:options + ["--prompt", "Search backlink: "]

	call fzf#run(fzf#wrap({
		\ 'options': l:options,
		\ 'source': l:list,
		\ 'sink': function('util#edit_shrink_fzf'),
	\ }, g:neuron_fullscreen_search))
endf

func! neuron#edit_zettel_last()
	if empty(g:_neuron_last_file)
		echo "Can't edit last zettel because none was visited before this!"
		return
	endif

	let g:_neuron_history_prevent_overwrite = 1
	let g:_neuron_history_pos = g:_neuron_history_pos - 1
	exec 'edit '.g:_neuron_last_file
endf

func! neuron#move_history(dir)
	let l:cursor = g:_neuron_history_pos + a:dir
	if l:cursor < 0 || (l:cursor - 1) > len(g:_neuron_history)
		echo "No history to navigate on that direction."
		return
	endif

	let g:_neuron_history_pos = l:cursor
	let g:_neuron_history_prevent_overwrite = 1
	exec 'edit '.g:_neuron_history[g:_neuron_history_pos]
endf

func! neuron#insert_zettel_last(as_folgezettel)
	if empty(g:_neuron_last_file)
		echo "Can't insert last zettel because none was visited before this!"
		return
	endif
	let l:zettelid = util#zettel_id_from_path(g:_neuron_last_file)
	call util#insert(l:zettelid, a:as_folgezettel)
endf

func! neuron#edit_zettel_new()
	if bufname('%') != ''
		w
	endif
	let l:zettel_path = util#new_zettel_path('')
	exec 'edit '.l:zettel_path
	call util#add_empty_zettel_body('')
endf

func! neuron#edit_zettel_new_from_cword()
	let l:title = expand("<cword>")
	let l:zettel_path = util#new_zettel_path(l:title)

	" replace cword with a link to the new zettel
	let l:zettel_id = util#zettel_id_from_path(l:zettel_path)
	execute "normal! ciw[[[".l:zettel_id."]]]"
	call neuron#add_virtual_titles()
	w

	exec 'edit '.l:zettel_path
	call util#add_empty_zettel_body(l:title)
	let g:_neuron_must_refresh_on_write = 1
endf

func! neuron#edit_zettel_new_from_visual()
	let l:prev = @p

	" title from visual selection
	execute 'normal! gv"pd'

	let l:title = @p
	let @p = l:prev

	let l:zettel_path = util#new_zettel_path(l:title)

	""" replace selection with a link to the new zettel
	let l:zettel_id = util#zettel_id_from_path(l:zettel_path)

	execute "normal! a[[[".l:zettel_id."]]]"
	call neuron#add_virtual_titles()
	w

	exec 'edit '.l:zettel_path
	call util#add_empty_zettel_body(l:title)
	let g:_neuron_must_refresh_on_write = 1
endf

func! neuron#edit_zettel_under_cursor()
	if !exists("g:_neuron_zettels_by_id")
		echo "Waiting until cache is populated."
		return
	end

	let l:zettel_id = trim(expand('<cword>'), "<>[]")
	if util#is_zettelid_valid(l:zettel_id)
		call neuron#edit_zettel(l:zettel_id)
	else
		let l:zettel_id = trim(expand('<cWORD>'), "<>[]")
		if util#is_zettelid_valid(l:zettel_id)
			call neuron#edit_zettel(l:zettel_id)
		else
			echo 'Word under cursor is not a known zettel!'
		endif
	endif
endf

func! neuron#edit_zettel(zettel_id)
	exec 'edit '.g:neuron_dir.a:zettel_id.g:neuron_extension
endf

func! neuron#refresh_cache(add_titles)
	if !executable(g:neuron_executable)
		echo "neuron executable not found!"
		return
	endif

	let g:_neuron_cache_add_titles = a:add_titles
	let l:cmd = g:neuron_executable.' -d "'.g:neuron_dir.'" query --uri z:zettels'
	if has('nvim')
		call jobstart(l:cmd, {
			\ 'on_stdout': function('s:refresh_cache_callback_nvim'),
			\ 'stdout_buffered': 1
		\ })
	elseif has('job')
		let l:jobopt = {
			\ 'exit_cb': function('s:refresh_cache_callback_vim'),
			\ 'out_io': 'file',
			\ 'out_name': g:neuron_tmp_filename,
			\ 'err_io': 'out'
		\ }
		if has('patch-8.1.350')
			let l:jobopt['noblock'] = 1
		endif
		call job_start(l:cmd, l:jobopt)
	else
		let l:cmd[2] = shellescape(g:neuron_dir)
		let l:data = system(join(cmd))
		call s:refresh_cache_callback(l:data)
	endif
endf

" vim 8
func! s:refresh_cache_callback_vim(channel, x)
	let l:data = readfile(g:neuron_tmp_filename)
	call job_start("rm " . g:neuron_tmp_filename)
	call s:refresh_cache_callback(join(l:data))
endf

" neovim
func s:refresh_cache_callback_nvim(id, data, event)
	call s:refresh_cache_callback(join(a:data))
endf

func! s:refresh_cache_callback(data)
	if (g:neuron_debug_enable)
		call writefile(split(a:data, "\n", 1), g:neuron_dir . 'query.json')
	endif
	let l:zettels = json_decode(a:data)["result"]

	call sort(l:zettels, function('util#zettel_date_sorter'))

	let g:_neuron_zettels_titles_list = {}
	let g:_neuron_zettels_by_id = []
	let g:_neuron_zettels_search_list = []
	let g:_neuron_backlinks = {}

	for z in l:zettels
		let g:_neuron_zettels_titles_list[z['zettelID']] = z['zettelTitle']
		call add(g:_neuron_zettels_by_id, { 'id': z['zettelID'], 'title': z['zettelTitle'], 'path': z['zettelPath'] })
		call add(g:_neuron_zettels_search_list, z['zettelID'].":".substitute(z['zettelTitle'], ':', '-', ''))
		let g:_neuron_backlinks[z['zettelID']] = []
	endfor

	for z in l:zettels
		if !empty(z['zettelQueries'])
			for l in z['zettelQueries']
				if l[0][0] == 'ZettelQuery_ZettelById'
					let l:key = l[0][1][0]
					if has_key(g:_neuron_backlinks, l:key)
						call add(g:_neuron_backlinks[l[0][1][0]], z['zettelID'])
					endif
				endif
			endfor
		endif
	endfor

	if g:_neuron_cache_add_titles == 1
		call neuron#add_virtual_titles()
	endif
	let g:_neuron_cache_add_titles = 1

	if !empty(g:_neuron_queued_function)
		call call(g:_neuron_queued_function[0], g:_neuron_queued_function[1])
		let g:_neuron_queued_function = []
	endif
endf

" used by gzu/gzl (insert_zettel_last, edit_zettel_last)
let g:_neuron_last_file = ""
let g:_neuron_current_file = ""

" used by gzu/gzl/gzU/gzP (move_history)
let g:_neuron_history = []
let g:_neuron_history_pos = -1
let g:_neuron_history_prevent_overwrite = 0

" used when we first open vim
let g:_neuron_did_init = 0

func! neuron#on_enter()
	let g:_neuron_last_file = g:_neuron_current_file
	let g:_neuron_current_file = expand("%s")

	if !g:_neuron_history_prevent_overwrite
		let g:_neuron_history = g:_neuron_history[0:g:_neuron_history_pos]
		call add(g:_neuron_history, expand("%s"))
		let g:_neuron_history_pos = g:_neuron_history_pos + 1
	endif

	call neuron#update_backlinks(0)

	if g:_neuron_did_init
		return
	endif
	let g:_neuron_did_init = 1
	call neuron#refresh_cache(1)
endf

let g:_neuron_must_refresh_on_write = 0
func! neuron#on_write()
	if g:_neuron_must_refresh_on_write
		call neuron#refresh_cache(1)
	else
		call neuron#add_virtual_titles()
	end
endf

func! neuron#update_backlinks(show)
	let l:is_open = 0
	if a:show == 0
		for win in range(1, winnr('$'))
			if getwinvar(win, '_neuron_backlinks')
				let l:is_open = 1
			endif
		endfor
		if l:is_open == 0
			return
		endif
	endif

	let l:current_zettel = util#current_zettel()
	if empty(l:current_zettel)
		return
	endif

	let l:output = ["# Backlinks for '" . l:current_zettel . "'", ""]
	let l:links = get(g:_neuron_backlinks, l:current_zettel, [])

	if empty(l:links)
		let l:output += ["None."]
	endif

	for id in l:links
		let l:title = g:_neuron_zettels_titles_list[id]
		let l:output += ["- [[".id."]] ".title]
	endfor

	"if it exists, switch and update
	for win in range(1, winnr('$'))
		if getwinvar(win, '_neuron_backlinks')
			let l:current_window = win_getid()
			call win_gotoid(win_getid(win))
			setlocal modifiable
			%delete
			call setline(1, l:output)
			setlocal nomodifiable
			call win_gotoid(l:current_window)

			return
		endif
	endfor

	let l:savesplitright = &splitright
	let &splitright = g:neuron_backlinks_vsplit_right
	if g:neuron_backlinks_vsplit == 1
		exe g:neuron_backlinks_size . 'vnew'
	else
		exe g:neuron_backlinks_size . 'new'
	endif
	let &splitright = l:savesplitright

	let l:current_window = win_getid()
	let w:_neuron_backlinks=1
	setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile ft=markdown
	call setline(1, l:output)
	setlocal nomodifiable
	call win_gotoid(l:current_window)
endfunc

func! neuron#toggle_backlinks()
	for win in range(1, winnr('$'))
		if getwinvar(win, '_neuron_backlinks')
			execute win . 'windo close'

			return
		endif
	endfor

	call neuron#update_backlinks(1)
endfunc

" Parse the current tags and return a list
func! neuron#tags_parse()
	let [l:line_tags, l:line_tags_end] = neuron#tags_position()

	if l:line_tags == -1
		return
	endif

	let l:all_tags = []

	if l:line_tags_end - l:line_tags == 1
		"handle single line
		let l:tags = matchlist(getline(l:line_tags), '\v\[(.*)\]')
		if empty(l:tags)
			"nothing, blank line
			return l:all_tags
		else
			if empty(l:tags[1])
				" here it would be []
				return l:all_tags
			else
				let l:tags = l:tags[1]
				let l:all_tags = split(l:tags, ',')
				let l:i = 0
				for tag in l:all_tags
					let l:all_tags[l:i] = trim(tag)
					let l:i += 1
				endfor

				return l:all_tags
			endif
		endif
	endif

	"handle multiline
	let l:i = l:line_tags + 1
	while l:i < l:line_tags_end
		let l:line = getline(l:i)
		"match from start of line then any number of spaces,
		"then a dash (-), then any number of spaces, then everything to the end of the line
		let l:tag = matchlist(getline(l:i), '\v^\s*-\s*(.+)$')
		if !empty(l:tag)
			call add(l:all_tags, l:tag[1])
		endif
		let l:i += 1
	endwhile

	return l:all_tags
endfunc

" Work out where the current tags are if they are present at all
" Returns list of the start and end lines
func! neuron#tags_position()
	let l:curpos = getpos('.')
	normal! G
	let l:line_end_matter = search('^---', 'bW')
	if !l:line_end_matter
		echom "No front matter found."

		return [-1, -1]
	endif
	let l:line_start_matter = search('^---', 'bW')
	if !l:line_start_matter
		echom "No front matter found."

		return [-1, -1]
	endif

	call setpos('.', [l:curpos[0], l:line_end_matter, 1])

	let l:line_tags = search('\v\c^'.g:neuron_tags_name.':', 'bW')
	if !l:line_tags
		"no tags key
		call setpos('.', l:curpos)

		return [0, 0]
	endif

	let l:line_tags_end = l:line_end_matter

	 "search down to the next key
	call setpos('.', [l:curpos[0], l:line_tags, 1])
	let l:next_key = search('\v^\w+:', 'n', l:line_end_matter)
	if l:next_key > 0
		let l:line_tags_end = l:next_key
	endif

	call setpos('.', l:curpos)

	return [l:line_tags, l:line_tags_end]
endfunc

" Update the current tags with the passed in tag
func! neuron#tags_update(tag)
	let l:curpos = getpos('.')

	"add tag to list of current tags
	let l:tag = trim(a:tag)
	let l:tags = neuron#tags_parse()

	if len(l:tags) == 0
		call add(l:tags, l:tag)
	else
		let l:found = 0
		for t in l:tags
			if t == l:tag
				let l:found = 1
			endif
		endfor
		if l:found == 1
			echom "Tag already exists."

			return
		else
			call add(l:tags, l:tag)
		endif
	endif

	let [l:line_tags, l:line_tags_end] = neuron#tags_position()

	if l:line_tags == -1
		return
	endif

	"handle if there is no current tags key
	if l:line_tags == 0
		"go to end, search backwards to front matter sep
		normal! G
		let l:line_tags = search('^---', 'bW')
	else
		call deletebufline('', l:line_tags, l:line_tags_end - 1)
	endif

	"inline
	if g:neuron_tags_style == 'inline'
		call append(l:line_tags - 1, g:neuron_tags_name.": [" . join(l:tags,',') . "]")
		call setpos('.', l:curpos)

		return
	endif

	"multiline
	call append(l:line_tags - 1, g:neuron_tags_name.":")
	let l:offset = 0
	for t in l:tags
		call append(l:line_tags + l:offset, '  - ' . t)
		let l:offset += 1
	endfor

	call setpos('.', l:curpos)
endfunc

" Add a new tag, takes optional param of the tag
func! neuron#tags_add_new(...)
	let l:tag = get(a:, 1, 0)
	if empty(l:tag)
		let l:tag = input('Tag to add: ')
	endif

	call neuron#tags_update(l:tag)
endfunc

" Return children for hierarchical tags
func! neuron#tags_add_children(tag_parent, tag_name, tag_children)
	if empty(a:tag_children)
		return [a:tag_parent . a:tag_name]
	endif

	let l:new_tags = []
	for l:child in a:tag_children
		let l:child_tag = neuron#tags_add_children(a:tag_parent . a:tag_name . '/', l:child['name'], l:child['children'])
		call extend(l:new_tags, l:child_tag)
	endfor

	call add(l:new_tags, (a:tag_parent . a:tag_name))

	return l:new_tags
endfunc

" Add tags from a selection list
func! neuron#tags_add_select()
	" TODO: use cache
	let l:cmd = g:neuron_executable.' -d "'.g:neuron_dir.'" query -u z:tags 2>/dev/null'
	let l:data = system(l:cmd)
	let l:tags = json_decode(l:data)["result"]
	if empty(l:tags)
		echom 'No existing tags found.'

		return
	endif

	let l:existing_tags_search = []
	for t in l:tags
		let l:child_tags = neuron#tags_add_children('', t['name'], t['children'])
		call extend(l:existing_tags_search, l:child_tags)
	endfor

	call fzf#run(fzf#wrap({
		\ 'options': util#get_fzf_options('Insert tag: ', 0, []),
		\ 'source': l:existing_tags_search,
		\ 'sink': function('neuron#tags_add_new'),
	\ }, g:neuron_fullscreen_search))
endfunc

" Search for zettels by a given tag
func! neuron#tags_search()
	let l:tag = input('Search by tag: ')

	"TODO: use cache
	let l:cmd = g:neuron_executable.' -d "'.g:neuron_dir.'" query -t '.l:tag
	let l:data = system(l:cmd)
	let l:zettels = json_decode(data)["result"]
	if empty(l:zettels)
		echom 'No results.'
		return
	endif

	let l:zettel_tag_search = []
	for z in l:zettels
		call add(l:zettel_tag_search, z['zettelID'].":".substitute(z['zettelTitle'], ':', '-', ''))
	endfor

	call fzf#run(fzf#wrap({
		\ 'options': util#get_fzf_options('Search tag: '.l:tag),
		\ 'source': l:zettel_tag_search,
		\ 'sink': function('util#edit_shrink_fzf'),
	\ }, g:neuron_fullscreen_search))
endfunc
