fuzzee.vim
==========

Fuzzee.vim will tab-complete paths relative to the current working directory in
Vim and also the current buffer for use with `:e[dit]` and `:E[xplore]`. It also
ignores files, directories, and filetypes listed in the user-defined
`wildignore` setting.

Install
-------

Install with [vim-pathogen](https://github.com/tpope/vim-pathogen) in your `~/.vimbundles/` folder. 

Or you can extract `fuzzee.vim` from `plugins/` and place it in your `~/.vim/plugins/` directory with the others.

Usage
-----

If your current buffer is `foo.txt` and you'd like to edit `bar.txt` from the
same directory then any combination the letters in the filename will edit it.
For instance, `:F bt` will complete to `bar.txt` if it is the only file with `b`
and `t` in it's name. Otherwise, it will expand to all possible matches relative
to the current buffer. `birthday_party.vim` would be matched but `funcakes.txt`
wouldn't. 

Navigate to other directories simply by typing their paths. `~` (or
the mistyped \`) will expand the the user's `$HOME`.

If a filepath is fuzzily typed such as `ap/cf` for `app/coffeescripts`,
Fuzzee.vim will autocomplete to that path. For searching files within a given
directory, append a `/` such as `:F app/cf/`, hit `<TAB>`, and it will
autocomplete any files in `app/coffeescripts/`. Omitting the trailing `/` as in
`ap/cf` will open the `:Explore` command on that directory opening up your file explorer in vim.

`:F .` will open up the explorer on whatever your current Vim working directory
is. `:F ` with no arguments will open up the explorer on the current buffer.

Tips
----

Use Fuzzee.vim for exploring project directories quickly with `cmap`. For
instance, to fuzzy match any javascripts in your `public` directory, save the
following in your `.vimrc`.

    set wcm=<C-z>
    cnoremap ,pj <S-Left>public/javascripts/<End><C-z>

This let's you type `:F foo,pj` to expand the first file that matches `f*o*o*`
within that directory. See `:h wcm` and `:h mapmode-c` for more details.

Hitting `<C-w>` with any expanded path deletes back to the last Word - use to move up directories quickly.

Some recommended vimrc settings:

    nnoremap <Leader>f :F <Space> 
    set wildmode=list,full 
    set wildmenu 
    set wildignore+=
        \*.png,*.jpg,*.pdf, 
        \CVS,SVN, 
        \ " more files to ignore here

This plugin leverages `expand("%:h")` in Vim which gets weird sometimes when in
a directory. Mostly it happens when navigating to directories when using `:edit`
with a trailing `/` at the end of the argument. So try not to do that.

Links
-----

[GitHub Repo](http://github.com/mattsacks/vim-fuzzee/)  
[vim.org](http://www.vim.org/scripts/script.php?script_id=3716)  
[Github Author](http://github.com/mattsacks/)  
[Twitter](http://twitter.com/mattsa)  

Credit to [@tpope](https://github.com/tpope) for his fuzzy-globbing utility.
