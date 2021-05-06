# neuron.vim
Manage your [Zettelkasten](https://neuron.zettel.page/2011401.html) with the
help of [neuron](https://github.com/srid/neuron) in {n}vim.

(This is an actively maintaned fork of [`ihsanturk/neuron.vim`](https://github.com/ihsanturk/neuron.vim) that works with newer versions of `neuron` and changes basically everything, with extra features, commands and different options.)

![usage-photo](screenshot.png)

## Requirements

- [neuron](https://github.com/srid/neuron)
- [fzf](https://github.com/junegunn/fzf.vim)
- any grep-like tool (such as `grep`,
[ag](https://github.com/mizuno-as/silversearcher-ag) or
[rg](https://github.com/BurntSushi/ripgrep)) if you intend to use the
content search command. See [below](#content-search-tool) for how to specify
the tool used for the content search.

## Installation
### Using [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'junegunn/fzf.vim'
Plug 'fiatjaf/neuron.vim'
```

### Using [home-manager](https://github.com/rycee/home-manager)
There are several ways to manage {n}vim plugins with home-manager. The current release has been tested with the `programs.neovim` module (tracking nixpkgs-unstable) like so:
```nix
{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      neuron-vim
      # ...
    ];
  };
  # ...
}
```

## Usage

1. Open a zettel with `vim` or `nvim`. On `nvim` it should
    - show a virtual floating text on the first line saying how many backlinks it has;
    - show a virtual title for each linked zettel in the body.

Most operations are executed in normal mode

2. `gzZ` shows a list of backlinks. Selecting one will navigate to it.
3. `gzz` shows a list of all zettels, you can search their titles. Selecting one will navigate to it.
4. Type `gzi` to show the same `gzz` list. Selecting one will insert a link to it right in front of the your cursor. `gzI` instead will insert a folgezettel link (`[[[...]]]`). You can also select a zettel from insert mode with `<c-x><c-u>` or `<c-x><c-y>` and then insert a normal link or a folgezettel link respectively.
5. If you put your cursor on top of a link to another zettel and press `gzo` you'll navigate to that.
6. `gzl` inserts a link to the previous zettel you visited.
    - `gzL` will do the same but with a folgezettel.
7. `gzu` goes back after editing another zettel type.
    - `gzu` repeatedly will cycle between the two last visited zettels.
9. `gzU` goes back multiple times in the history of visited zettels (and `gzP` will go forward).
10. `gzn` creates a new blank zettel
11. `gzN` creates a new zettel using the current word under the cursor as its title.
    - if you're in visual selection mode `gzN` will instead use the selected text (only the first line if there are more than one selected). This will replace the selected text or current word with a link to the newly-created zettel.
12. `gzs` works like `gzz`, but instead it searches the content of the zettels, not only the title. For this it calls the external command `ag`.
13. `gzt` will allow you to insert new tags or `gzT` will show you a list of existing tags to then insert.

## Customization

### Zettel ID generation
`neuron.vim` uses a custom function to generate ids for new zettels that it creates, bypassing `neuron new` completely. By default it generates a random hex string of 8 characters. You can hook into the process by defining a function `g:CustomNeuronIDGenerator` in your `.vimrc` that takes an optional `title` argument. For example:

To make it use the title as kebab-cased ID (when using `gzN`):

```
func! g:CustomNeuronIDGenerator(title)
    return substitute(a:title, " ", "-", "g")
endf
```

If `g:CustomNeuronIDGenerator` is not defined in your `.vimrc` or returns an empty string, `neuron.vim` will fall back to generating random IDs.

### Content search tool
You can set `g:neuron_preferred_greplike_command` to any shell command that
returns output similar with
```shell
grep --recursive --line-number --exclude-dir='.*'
```
For example, to use ripgrep
```vim
let g:neuron_preferred_greplike_command = "rg --column --line-number --no-heading --color=always --smart-case"
```
If not set, defaults to `ag` for backwards compability.
