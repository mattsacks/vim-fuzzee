fuzzee.vim
==========

Fuzzee.vim will tab-complete paths relative to the current working directory in
Vim and also the current buffer for use with `:e[dit]` and `:E[xplore]`. It also
ignores files, directories, and filetypes listed in the user-defined
`wildignore` setting and has support for multi-directory globbing.


Install
-------

Install with [vim-pathogen](https://github.com/tpope/vim-pathogen) in your
configured bundles folder.

Or you can extract `fuzzee.vim` from `plugins/` and place it in your
`~/.vim/plugins/` directory with the others.


Usage
-----

The `:F` command can be given any fuzzily-typed string that, when expanded,
matches some filepath on your system.

It accepts 3 different types of arguments:

* Strings that expand to files relevant to the current buffer
* The current working directory
* Absolute paths

Let's give an example working directory and how `:F` can be used to navigate
around it depending on what file you're currently viewing. Say the `cwd`, or
current working directory, looks something like:

**~/Dropbox/dev/project**

    app/
        coffeescripts/
    ******  application.coffee ******
            models.coffee
            collections.coffee
    lib/
        scripts.js
    public/
        stylesheets/
            sass/
            css/
        javascripts/
            application.js
            models.js
            collections.js
    Cakefile

First we'll use `:F` to  get to the working directory from a new Vim session in
your home directory. Any of the following are sufficient:

    :F ~/dr/de/pro  " search for /Users/you/*d*r*/*d*e*/*p*r*o*
    :F `*dro*oje    " globs for any *o*j*e* under /Users/you/*d*r*
    :F dr*project   " search for any filepath *d*r*p*r*o*j*e*c*t* under the cwd

Then, either `:FL` or `:FL .` will both work to change the local working
directory to the project path.

A quick `:F */alcf` will glob the current working directory for `*a*l*c*f*` to
edit `app/coffeescripts/application.coffee`.

By hitting `:F <TAB>`, Fuzzee.vim will show you everything in the current
buffer's directory first but that's only if you give it no arguments. So this
will be everything in `app/coffeescripts/`. To move to `models.coffee` quickly,
type `:F md`. Remember, by default it will always refer first in relation to the
current buffer.

`:F ./` will search for anything in the current working directory.  However,
it's not always necessary. All of the following work to edit the `Cakefile` from
the currently edited .coffee file:

    :F cak          " search in the directory above the buffer for *c*a*k*. if 
                    " nothing is found, then search the current working directory.
    :F ./ckf        " search in the current working directory for *c*k*f*
    :F */cake       " glob for any filepath of *c*a*k*e* under the cwd

Respectively, `:F ../` will search for anything in the directory above what
you're currently editing. So at `app/coffeescripts/application.coffee`, then that
will look in `app/coffeescripts`.

To open directories quickly, Fuzzee.vim can also be invoked with no arguments or
just a `.`
    
    :F              " opens up the directory above the current buffer
    :F .            " open the current working directory

Say you just `:q ` the application.coffee file in vim but you want to open it back
up quickly.

    :FB applcof     " open a buffer with matching fuzzy string "*a*p*p*l*c*o*f*"
                    " either as a relation to the cwd or full path

The fuzzy-expansion works for any filepath on your system no matter where you
are but it can always backtrace to the current working directory as well.
Primarily, it searches in relation to what you're currently viewing.


Commands
--------

* `:F `  - open a fuzzy-string filepath
* `:FS` - open up in a split
* `:FV` - open in a vertical split
* `:FT` - open in a new tab
* `:FL` - change local working directory
* `:FC` - change working directory
* `:FB` - open a hidden or switch to an active buffer


Tips
----

Some recommended vimrc settings:

    nnoremap <Leader>f :F<Space>
    nnoremap <Leader>t :F */
    set wildmode=list:longest,full
    set wildmenu
    set wildignore+=
        \*.png,*.jpg,*.pdf,
        \CVS,SVN,
        \" more files to ignore here
    set switchbuf=usetab

Fuzzee.vim can be used for exploring common project filepaths and directories
quickly with `cmap`. For instance, to match any javascripts in your `public`
directory, try out the following:

    set wcm=<C-z> " this is just a way to map <Tab> completion
    cnoremap ,pj  <S-Left>public/javascripts/<End><C-z>
    cnoremap ,,pj public/javascripts/<C-z>

This let's you type `:F foo,pj` to expand the first file that matches `*f*o*o*`
within that directory. Adding a comma as `:f ,,pj` will show the autocomplete
menu for that directory. See `:h wcm` and `:h mapmode-c` for more details.

Vim has a global working directory `:cd` and a local to window (that includes
splits) working directory `:lcd`. Use these for making project paths relative
as `app/dir` and not absolute like `/Users/foo/dev/app/dir`.

Hitting `<C-w>` with any expanded path deletes back to the last Word - use to
move up directories quickly.

The `'switchbuf'` setting allows the `:FB` command to find files in other tabs or
splits with a matching fuzzy-name. If the buffer is hidden (a file that was `:q`)
then the command will just open the buffer in the current window.

Links
-----

[GitHub Repo](http://github.com/mattsacks/vim-fuzzee/)  
[vim.org](http://www.vim.org/scripts/script.php?script_id=3716)  
[Github Author](http://github.com/mattsacks/)  
[Twitter](http://twitter.com/mattsa)

Credit to [@tpope](https://github.com/tpope) for his fuzzy-globbing utility.
