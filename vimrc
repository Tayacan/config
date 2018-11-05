syntax on

" write when we :make
set autowrite

colorscheme torte

" indentation
set expandtab
set tabstop=4
set softtabstop=4
set shiftround
set autoindent
set smartindent
set hlsearch

" Swap-files
set backupdir=/var/tmp/vim-maya/swap
set directory=/var/tmp/vim-maya/swap

filetype indent plugin on

set pastetoggle=<F12>
:nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>
