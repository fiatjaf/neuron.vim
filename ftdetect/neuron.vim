let g:zextension = get(g:, 'zextension', '.md')
let g:zkdir = get(g:, 'zkdir', $HOME.'/zettelkasten/')

" search for neuron.dhall
let s:current = expand("%:p")
if s:current == ''
	let s:current = getcwd()
endif
let s:dir = fnamemodify(s:current, ":h:r")
while s:dir != "/"
	if filereadable(s:dir."/neuron.dhall")
		let g:zkdir = s:dir."/"
		break
	endif
	let s:dir = fnamemodify(s:dir, ":h:r")
endwhile

if exists('b:did_ftdetect') | finish | endif
aug neuron
	exec ':au! BufRead '.g:zkdir.'*'.g:zextension.' call neuron#add_virtual_titles()'
	exec ':au! BufEnter '.g:zkdir.'*'.g:zextension.' call neuron#on_enter()'
	exec ':au! BufWrite '.g:zkdir.'*'.g:zextension.' call neuron#on_write()'
aug END
let b:did_ftdetect = 1
