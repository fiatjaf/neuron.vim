" Mode transition specifies how to enter insert mode, usually either 'a' or
" 'i'. This extra parameter is necessary for properly handling replacement.
" Consider for example the case of executing neuron#edit_zettel_from_visual on
" text starting in the first position on the line. The cursor ends up in the
" first position in the line, and appending would cause the new link to be
" offset by a space, whereas the desired result is having the new link
" start at the first character.
func! util#insert(zettelid, as_folgezettel, mode_transition)
	if a:as_folgezettel
		let l:formatted = "[[[".a:zettelid."]]]"
	else
		let l:formatted = "[[".a:zettelid."]]"
	endif

	let l:word_under = expand('<cword>')
	if !empty(l:word_under) && empty(trim(l:word_under, "[]<>"))
		" erase things like '[[]]' before adding
		execute "normal! diwi".l:formatted
	else
		execute "normal! ".a:mode_transition.l:formatted
	endif

	call neuron#add_virtual_titles()
	let g:_neuron_must_refresh_on_write = 1
endf

func! util#is_zettelid_valid(zettelid)
	if empty(a:zettelid)
		return 0
	end
	if !empty(get(g:_neuron_zettels_titles_list, util#deform_zettelid(a:zettelid)))
		return 1
	else
		return 0
	end
endf

func! util#get_zettel_in_line(line)
	for zettel in g:_neuron_zettels_by_id
		let l:matched = matchstr(a:line, '\[\['.zettel['id'].'\]\]')
		if !empty(l:matched)
			return l:matched[2:-3]
		end
	endfor
	return ""
endf

func! util#get_zettel_from_fzf_line(line)
	return split(a:line, ":")[0]
endf

func! util#deform_zettelid(zettelid)
	if a:zettelid =~ "\[\[\[\?.*\]\]\]\?"
		return substitute(a:zettelid, '\[\[\[\?\([0-9a-zA-Z_-]\+\)\(?cf\)\?\]\]\]\?', '\1', 'g')
	else
		return a:zettelid
	end
endf

func! util#insert_shrink_fzf(line)
	call util#insert(util#get_zettel_from_fzf_line(a:line), 0, "a")
endf

func! util#insert_shrink_fzf_folgezettel(line)
	call util#insert(util#get_zettel_from_fzf_line(a:line), 1, "a")
endf

func! util#edit_shrink_fzf(line)
	call neuron#edit_zettel(util#get_zettel_from_fzf_line(a:line))
endf

func! util#zettel_date_sorter(a, b)
	let l:ad = util#zettel_date_getter(a:a)
	let l:bd = util#zettel_date_getter(a:b)
	if l:ad == l:bd
		return 0
	elseif l:ad > l:bd
		return -1
	else
		return 1
	endif
endf

func! util#zettel_date_getter(z)
	let l:date = get(a:z, 'zettelDate', ['1970-01-01'])
	if type(l:date) != type([])
		let l:date = ['1970-01-01']
	endif
	return join(l:date)
endf

" get the fzf options
" optional params of:
" - the prompt to use, default 'Search zettel: '
" - whether to use preview, default True
" - fzf options to use if not the global ones
func! util#get_fzf_options(...)
	let l:ncol = (&columns - 4) / 2
	let l:ext = g:neuron_extension

	let l:prompt = get(a:, 1, 'Search zettel: ')
	let l:use_preview = get(a:, 2, 1)
	let l:ext_options = get(a:, 3, g:neuron_fzf_options)

	let l:options = extend(deepcopy(l:ext_options), ['--prompt', l:prompt])

	if l:use_preview == 1
		let l:options = extend(deepcopy(l:options), ['--preview', "echo {} | sed 's/:.*/".l:ext."/' | xargs fold -w ".l:ncol." -s"])
	endif

	return l:options
endf

func! util#current_zettel()
	return util#zettel_id_from_path(expand("%s"))
endf

func! util#zettel_id_from_path(path)
	return fnamemodify(a:path, ':t:r')
endf

func! util#new_zettel_path(title)
	return g:neuron_dir.util#generate_id(a:title).g:neuron_extension
endf

func! util#generate_id(title)
	let l:id = ""

	" mega-customization through functions to generate the zettel id
	if exists('*g:CustomNeuronIDGenerator')
		let l:id = g:CustomNeuronIDGenerator(a:title)
	endif

	if empty(l:id)
		let l:id = system("od -An -N 4 -t 'x4' /dev/random")
	endif

	return trim(l:id)
endfunc

func! util#add_empty_zettel_body(title)
	let l:body = [
	  \ '---',
	  \ 'date: '.strftime("%Y-%m-%dT%H:%M"),
	  \ '---',
	  \ '',
	  \ '# '.a:title
	\ ]
	call append(0, l:body)
endf
