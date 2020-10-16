"           ╭─────────────────────neuron.vim──────────────────────╮
"           Maintainer:     ihsan, ihsanl[at]pm[dot]me            │
"           Description:    Take zettelkasten notes using neuron  │
"           Last Change:    2020 Jul 24 23:40:47 +03, @1595623251 │
"           First Appeared: 2020 May 24 16:20:56 +03, @1590326456 │
"           License:        MIT                                   │
"           ╰─────────────────────────────────────────────────────╯

if exists("g:_neuron_loaded")
	finish
endif
let g:_neuron_loaded = 1

let g:neuron_backlinks_size = get(g:, 'neuron_backlinks_size', 40)
let g:neuron_backlinks_vsplit = get(g:, 'neuron_backlinks_vsplit', 1)
let g:neuron_backlinks_vsplit_right = get(g:, 'neuron_backlinks_vsplit_right', 1)
let g:neuron_executable = get(g:, 'neuron_executable', system('which neuron | tr -d "\n"'))
let g:neuron_fullscreen_search = get(g:, 'neuron_fullscreen_search', 0)
let g:neuron_fzf_options = get(g:, 'neuron_fzf_options', ['-d',':','--with-nth','2'])
let g:neuron_inline_backlinks = get(g:, 'neuron_inline_backlinks', 1)
let g:neuron_no_mappings = get(g:, 'neuron_no_mappings', 0)

func! RandomID(title)
	return system("od -An -N 4 -t 'x4' /dev/random")
endf

" mega-customization through functions to generate the zettel id
func! g:NeuronGenerateID(title)
	if exists('*g:CustomNeuronIDGenerator')
		return g:CustomNeuronIDGenerator(a:title)
	else
		return RandomID(a:title)
	endif
endfunc

let g:_neuron_rib_job = -1

nm <silent> <Plug>NeuronRibStop :<C-U>call rpc#stop_server()<cr>
nm <silent> <Plug>NeuronRibStart :<C-U>call rpc#start_server()<cr>
nm <silent> <Plug>EditZettelNew :<C-U>call neuron#edit_zettel_new()<cr>
nm <silent> <Plug>EditZettelSearchContent :<C-U>call neuron#search_content(0)<cr>
nm <silent> <Plug>EditZettelSearchContentUnderCursor :<C-U>call neuron#search_content(1)<cr>
nm <silent> <Plug>EditZettelNewFromCword :<C-U>call neuron#edit_zettel_new_from_cword()<cr>
nm <silent> <Plug>EditZettelNewFromVisual :<C-U>call neuron#edit_zettel_new_from_visual()<cr>
nm <silent> <Plug>EditZettelLast :<C-U>call neuron#edit_zettel_last()<cr>
nm <silent> <Plug>NeuronRefreshCache :<C-U>call neuron#refresh_cache()<cr>
nm <silent> <Plug>EditZettelSelect :<C-U>call neuron#edit_zettel_select()<cr>
nm <silent> <Plug>EditZettelBacklink :<C-U>call neuron#edit_zettel_backlink()<cr>
nm <silent> <Plug>EditZettelUnderCursor :<C-U>call neuron#edit_zettel_under_cursor()<cr>
nm <silent> <Plug>InsertZettelLast :<C-U>call neuron#insert_zettel_last(0)<cr>
nm <silent> <Plug>InsertZettelSelect :<C-U>call neuron#insert_zettel_select(0)<cr>
nm <silent> <Plug>ToggleBacklinks :<C-U>call neuron#toggle_backlinks()<cr>

if !exists("g:neuron_no_mappings") || ! g:neuron_no_mappings
	nm gzn <Plug>EditZettelNew
	nm gzN <Plug>EditZettelNewFromCword
	vm gzN <esc><Plug>EditZettelNewFromVisual
	nm gzb <Plug>NeuronRibStart
	nm gzr <Plug>NeuronRefreshCache
	nm gzu <Plug>EditZettelLast
	nm gzU :<C-U>call neuron#move_history(-1)<cr>
	nm gzP :<C-U>call neuron#move_history(1)<cr>
	nm gzz <Plug>EditZettelSelect
	nm gzZ <Plug>EditZettelBacklink
	nm gzo <Plug>EditZettelUnderCursor
	nm gzs <Plug>EditZettelSearchContent
	nm gzS <Plug>EditZettelSearchContentUnderCursor
	nm gzl <Plug>InsertZettelLast
	nm gzi <Plug>InsertZettelSelect
	nm gzL :<C-U>call neuron#insert_zettel_last(1)<cr>
	nm gzI :<C-U>call neuron#insert_zettel_select(1)<cr>
	nm gzv <Plug>ToggleBacklinks
end

com! NeuronRibStart :call rpc#start_server()
com! NeuronRibStop  :call rpc#stop_server()

" : vim: set fdm=marker :
