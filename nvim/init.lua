--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global shortcuts/helper
--------------------------------------------------------------------------------------------------------------------------------------------------------
local cmd = vim.cmd
local o = vim.o
local b = vim.b
local wo = vim.wo
local g = vim.g

function Map(mode, shortcut, command)
	vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = false, silent = true })
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Plugin enabler
--------------------------------------------------------------------------------------------------------------------------------------------------------
cmd([[
call plug#begin('$XDG_CONFIG_HOME/nvim/autoload/plugged')
	Plug 'tomasiser/vim-code-dark'					" Install the vscode's codedark theme
	Plug 'nvim-lualine/lualine.nvim'				" Add a fancy bottom bar with details
	Plug 'lewis6991/gitsigns.nvim'					" Add the left column indicating git line status and preview window
	Plug 'norcalli/nvim-colorizer.lua'				" Colourize RGB codes to it designated colour
	Plug 'tpope/vim-surround'						" Quickly surround word with given symbol
	Plug 'nvim-telescope/telescope.nvim'			" Add fuzzy finder to files, command and more
	Plug 'nvim-lua/plenary.nvim'					" Telescope dependency
	Plug 'windwp/nvim-autopairs'					" Automatic pairs of ( [ { insertion
	Plug 'kyazdani42/nvim-tree.lua'					" Add a fancy file explorer
	Plug 'kyazdani42/nvim-web-devicons'				" nvim-tree dependency for file icons
	Plug 'tommcdo/vim-lion'							" add the vmap gl<SYMBOL> to vertical align to the given symbol
	Plug 'luochen1990/rainbow'						" Colourize multiple inner level to ( [ {
	Plug 'ntpeters/vim-better-whitespace'			" Automatic white spaces trimming
	Plug 'chrisbra/csv.vim'							" CSV file handling
	Plug 'neoclide/coc.nvim', {'branch': 'release'} " LSP Functionnalities
call plug#end()
]])

g.coc_global_extensions = {	"coc-cspell-dicts", "coc-spell-checker", "coc-json", "coc-pyright", "coc-lua", "coc-prettier", "coc-docker", "coc-java",
							"coc-sh", "coc-markdownlint", "coc-markdown-preview-enhanced", "coc-webview", "coc-clangd"}

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- General settings config
--------------------------------------------------------------------------------------------------------------------------------------------------------
wo.t_Co						= "256"														-- Support 256 colours
wo.t_ut						= ""														-- Reset the value to apply colorscheme
cmd("colorscheme			  codedark")												-- Set the colour scheme to codedark (VSCode's dark+)
o.termguicolors				= true														-- Enable 24-bit RGB colours in the terminal
o.syntax					= "true"													-- Enables syntax highlighting
o.listchars					= 'eol:﬋,tab:→ ,trail:•,extends:>,precedes:<,space:·,nbsp:ﴔ'-- List of whitespace characters replacement (see :h listchars)
o.list						= true														-- Enable replacement of listchars
o.hidden					= true														-- Required to keep multiple buffers open multiple buffers
o.wrap						= false														-- Display long lines as just one line
o.encoding					= 'UTF-8'													-- The encoding displayed
o.fileencoding				= 'UTF-8'													-- The encoding written to file
o.ruler						= true														-- Show the cursor position all the time
cmd("set iskeyword			+=-")														-- treat dash separated words as a word text object
o.tabstop					= 4															-- Set the width of a tab
o.shiftwidth				= 4															-- Change the number of space characters inserted for indentation
o.smartindent				= true														-- Does smart autoindenting when starting a new line
o.expandtab					= false														-- Disable the tab expansion of spaces
o.laststatus				= 0															-- Always display the status line
o.number					= true														-- Line numbers
o.relativenumber			= true														-- Relative number (enabled after number for hybrid mode)
o.cursorline				= true														-- Enable highlighting of the current line
o.showtabline				= 2															-- Always show tabs
o.showmode					= false														-- We don't need to see things like	-- INSERT -- any more
o.clipboard					= 'unnamedplus'												-- Copy paste between vim and everything else
o.foldmethod				= 'syntax'													-- Change the folding method to fold from { [ ...
o.foldlevel					= 99														-- Fold are open when you first open a file
o.visualbell				= true														-- Disable noise
o.splitbelow				= true														-- Horizontal splits will automatically be below
o.splitright				= true														-- Vertical splits will automatically be to the right
o.completeopt				= "menu,menuone,noselect"									-- Add LSP complete popup menu
o.signcolumn				= "yes"														-- Always draw the signcolumn with 1 fixed space width
o.title						= true														-- Change the window's title to the opened file name and directory
o.updatetime				= 200														-- Time before CursorHold triggers
cmd("set formatoptions		+=r")														-- Add asterisks in block comments
cmd("set wildignore			+=*/node_modules/*,*/.git/*,*/venv/*,*/package-lock.json")	-- Ignore files in fuzzy finder
cmd("autocmd FileType python set noexpandtab")											-- Force disable expandtab on python's files

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Plugin config
--------------------------------------------------------------------------------------------------------------------------------------------------------
b.csv_arrange_align			= 'lc.'														-- Left align when using ArrangeColumn in a csv file "
g.rainbow_active			= 1															-- Enable rainbow plugin
g.better_whitespace_enabled = 1															-- Enable the vim-better-whitespace plugin
g.strip_whitespace_on_save	= 1															-- Remove trailing white spaces on save
g.strip_whitespace_confirm	= 0															-- Disable the confirmation message on stripping white spaces
g.lion_squeeze_spaces		= 1															-- Squeeze extra spaces when doing a vertical alignment

-- Configure the git colours palette
cmd([[
hi GitSignsAdd    guifg = #009900 ctermfg = 2
hi GitSignsChange guifg = #bbbb00 ctermfg = 3
hi GitSignsDelete guifg = #ff2222 ctermfg = 1
]])

require('lualine').setup {
	options = {
		theme = 'codedark'
	}
}

require('gitsigns').setup {
	keymaps = {
		['n <leader>hp'] = '<cmd>Gitsigns preview_hunk<CR>',
		['n <leader>hu'] = '<cmd>Gitsigns reset_hunk<CR>',
		['n [h'] = '<cmd>Gitsigns prev_hunk<CR><leader>hp',
		['n ]h'] = '<cmd>Gitsigns next_hunk<CR><leader>hp'
	},
	current_line_blame = true
}

require("nvim-autopairs").setup {}

require'nvim-tree'.setup {
	filters = {
		custom = {
			".git",
			"node_modules",
			"venv",
			"package-lock.json"
		}
	},
	actions = {
		open_file = {
			quit_on_open = true,
		}
	}

}

require'colorizer'.setup(
	{'*';},
	{
		RGB		 = true,	-- #RGB hex codes
		RRGGBB	 = true,	-- #RRGGBB hex codes
		names	 = true,	-- "Name" codes like Blue
		RRGGBBAA = true,	-- #RRGGBBAA hex codes
		rgb_fn	 = true,	-- CSS rgb() and rgba() functions
		hsl_fn	 = true,	-- CSS hsl() and hsla() functions
		css		 = true,	-- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
		css_fn	 = true		-- Enable all CSS *functions*: rgb_fn, hsl_fn
	})

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Key mapping config
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- set leader key to space
g.mapleader = ' '

-- Save buffer shortcut
Map('n', '<C-s>', ':w<CR>')

-- Close window shortcut (keeps buffer open)
Map('n', '<C-F4>', ':q!<CR>')
Map('n', '<F28>', '<C-F4>') -- F28 Is CTRL F4 in Linux : LPT You can type key code in insert mode !

-- Close buffer shortcut
Map('n', '<S-F4>', ':bd<CR>')
Map('n', '<F16>', '<S-F4>')

-- M is the ALT modifier key
Map('n', '<M-j>', ':resize -1<CR>')
Map('n', '<M-k>', ':resize +1<CR>')
Map('n', '<M-h>', ':vertical resize -1<CR>')
Map('n', '<M-l>', ':vertical resize +1<CR>')

-- Better tab movement
Map('n', '<S-l>', 'gt')
Map('n', '<S-h>', 'gT')

-- Fix terminal exit button
Map('t', '<Esc>', '<C-\\><C-n>')

-- Clear the highlighting of :set hlsearch
Map('n', '<C-m>', ':noh<CR>')

-- Disable the suspend signal
Map('n', '<C-z>', '<Nop>')

-- Better tabbing
Map('v', '<', '<gv')
Map('v', '>', '>gv')

-- Telescope keybinds
Map('n', '<C-p>', ':Telescope find_files<CR>')
Map('n', '<C-f>', ':Telescope live_grep<CR>')
Map('n', '<leader>f', ':Telescope grep_string<CR>')
Map('n', '<leader>t', ':Telescope help_tags<CR>')
Map('n', '<leader>c', ':Telescope commands<CR>')
Map('n', '<leader>b', ':Telescope buffers<CR>')

-- Open the nerd tree explorer
Map('n', '<C-b>', '<cmd>NvimTreeToggle<CR>')

-- COC keybinds
Map('v', '<leader>a', '<Plug>(coc-codeaction-selected)w')
Map('n', '<leader>a', '<Plug>(coc-codeaction-selected)w')
Map('n', 'gd', '<Plug>(coc-definition)')
Map('n', 'gy', '<Plug>(coc-type-definition)')
Map('n', 'gr', '<Plug>(coc-references)')
Map('n', 'gi', '<Plug>(coc-implementation)')
Map('n', '[g', '<Plug>(coc-diagnostic-prev)')
Map('n', ']g', '<Plug>(coc-diagnostic-next)')
Map('n', '<leader>r', '<Plug>(coc-rename)')
Map('n', '<leader>s', ':CocSearch ')
Map('n', '<leader>vd', ':CocDiagnostics<CR>')
Map('n', '<leader>vo', ':CocOutline<CR>')
Map('n', '<leader>vc', ':CocCommands<CR>')
Map('n', '<leader>ve', ':CocList extensions<CR>')

cmd([[
function! s:check_back_space() abort
	let col = col('.') - 1
	return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : <SID>check_back_space() ? "\<TAB>" : coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <silent><expr> <C-Space> coc#refresh()

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
	if (index(['vim','help'], &filetype) >= 0)
		execute 'h '.expand('<cword>')
	elseif (coc#rpc#ready())
		call CocActionAsync('doHover')
	else
		execute '!' . &keywordprg . " " . expand('<cword>')
	endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')"

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')
]])

