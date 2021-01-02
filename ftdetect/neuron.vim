let g:neuron_extension = get(g:, 'neuron_extension', '.md')
let b:neuron_dir = get(g:, 'neuron_dir', getcwd() . '/')

" if there is no neuron.dhall file in current dir then it is not a zettelkasten
if !filereadable(b:neuron_dir."neuron.dhall")
	finish
endif

if exists('b:did_ftdetect') | finish | endif
aug neuron
	exec ':au! BufRead '.fnameescape(b:neuron_dir).'*'.fnameescape(g:neuron_extension).' call neuron#add_virtual_titles()'
	exec ':au! BufEnter '.fnameescape(b:neuron_dir).'*'.fnameescape(g:neuron_extension).' call neuron#on_enter()'
	exec ':au! BufWrite '.fnameescape(b:neuron_dir).'*'.fnameescape(g:neuron_extension).' call neuron#on_write()'
aug END
let b:did_ftdetect = 1
