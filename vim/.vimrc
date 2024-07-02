" Show console
map ! :!<CR>

" Disable compatibility with vi which can cause unexpected issues
set nocompatible

" Automatically reload .vimrc
autocmd! bufwritepost .vimrc source %

" Enable type file detection
filetype on

" Enable filetype plugins
filetype plugin on
filetype indent on

" Turn syntax highlighting on
syntax on

" Turn on the Wild menu (wmnu)
set wildmenu

" Always show current position
set ruler
set number
set scrolloff=4

" Searching
set ignorecase
set smartcase
set hlsearch
set incsearch

" Turn backup off, since stuff is in git
set nobackup
set writebackup
set noswapfile

" Quitting mapping
map QQ :q!
map WW :wq
