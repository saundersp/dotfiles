--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global shortcuts/helper
--------------------------------------------------------------------------------------------------------------------------------------------------------
local cmd = vim.cmd
local o = vim.o
local b = vim.b
local wo = vim.wo
local g = vim.g

function map(mode, shortcut, command)
	vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = true, silent = true })
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Plugin enabler
--------------------------------------------------------------------------------------------------------------------------------------------------------
cmd([[
call plug#begin('$XDG_CONFIG_HOME/nvim/autoload/plugged')
	Plug 'tomasiser/vim-code-dark'			" Install the vscode's codedark theme
	Plug 'vim-airline/vim-airline'			" Adds the fancy bottom bar
	Plug 'vim-airline/vim-airline-themes' 	" Adds themes to airline
	Plug 'airblade/vim-gitgutter' 			" Add the left column indicating git line status
	Plug 'norcalli/nvim-colorizer.lua' 		" Colourize RGB codes to it designated colour
	Plug 'tpope/vim-surround'				" Quickly surround word with given symbol
	Plug 'nvim-telescope/telescope.nvim'	" Add fuzzy finder to files, command and more
	Plug 'nvim-lua/plenary.nvim'			" Telescope dependency
	Plug 'jiangmiao/auto-pairs'				" Automatic pairs of ( [ { insertion
	Plug 'kyazdani42/nvim-tree.lua'			" Add a fancy file explorer
	Plug 'kyazdani42/nvim-web-devicons' 	" nvim-tree dependency for file icons
	Plug 'tommcdo/vim-lion'					" add the vmap gl<SYMBOL> to vertical align to the given symbol
	Plug 'luochen1990/rainbow'				" Colourize multiple inner level to ( [ {
	Plug 'ntpeters/vim-better-whitespace'   " Automatic white spaces trimming
	Plug 'chrisbra/csv.vim'					" CSV file handling
	Plug 'neovim/nvim-lspconfig'			" Language Server Protocol configurator
	Plug 'williamboman/nvim-lsp-installer'	" Adds command helper to easily install LSP servers
	Plug 'glepnir/lspsaga.nvim'				" Adds common commands used in LSP
	Plug 'hrsh7th/nvim-cmp'					" Adds automatic completion
call plug#end()
]])

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- General settings config
--------------------------------------------------------------------------------------------------------------------------------------------------------
wo.t_Co 					= "256" 													-- Support 256 colours
wo.t_ut 					= ""														-- Reset the value to apply colorscheme
cmd("colorscheme			  codedark") 												-- Set the colour scheme to codedark (VSCode's dark+)
o.termguicolors 			= true														-- Enable 24-bit RGB colours in the terminal
o.syntax					= "true"													-- Enables syntax highlighting
o.listchars 				= 'eol:﬋,tab:→ ,trail:•,extends:>,precedes:<,space:·,nbsp:ﴔ'-- List of whitespace characters replacement (see :h listchars)
o.list  					= true														-- Enable replacement of listchars
o.hidden					= true														-- Required to keep multiple buffers open multiple buffers
o.wrap  					= false 													-- Display long lines as just one line
o.encoding					= 'UTF-8'													-- The encoding displayed
o.fileencoding  			= 'UTF-8'													-- The encoding written to file
o.ruler			 			= true														-- Show the cursor position all the time
cmd("set iskeyword			+=-")														-- treat dash separated words as a word text object
o.tabstop					= 4															-- Set the width of a tab
o.shiftwidth				= 4															-- Change the number of space characters inserted for indentation
o.smartindent				= true														-- Does smart autoindenting when starting a new line
o.laststatus				= 0															-- Always display the status line
o.number					= true														-- Line numbers
o.relativenumber			= true														-- Relative number (enabled after number for hybrid mode)
o.cursorline				= true														-- Enable highlighting of the current line
o.showtabline				= 2															-- Always show tabs
o.showmode					= false														-- We don't need to see things like	-- INSERT -- any more
o.clipboard					= 'unnamedplus'												-- Copy paste between vim and everything else
o.foldmethod				= 'syntax'													-- Change the folding method to fold from { [ ...
o.foldlevel					= 99														-- Fold are open when you first open a file
--o.shell		 			= 'bash'													-- Changes the internal terminal to bash
o.visualbell				= true														-- Disable noise
o.spell						= true														-- Enable built-in spell checking
o.spelllang					= "en_gb"													-- Change spell checking languages
o.splitbelow				= true														-- Horizontal splits will automatically be below
o.splitright				= true														-- Vertical splits will automatically be to the right

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Plugin config
--------------------------------------------------------------------------------------------------------------------------------------------------------
g.airline_theme				= 'codedark'												-- Set airline theme to codedark
b.csv_arrange_align			= 'lc.'														-- Left align when using ArrangeColumn in a csv file "
g.rainbow_active			= 1															-- Enable rainbow plugin
g.better_whitespace_enabled = 1															-- Enable the vim-better-whitespace plugin
g.strip_whitespace_on_save  = 1															-- Remove trailing white spaces on save
g.strip_whitespace_confirm  = 0															-- Disable the confirmation message on stripping white spaces
g.lion_squeeze_spaces		= 1															-- Squeeze extra spaces when doing a vertical alignment

-- Configure the git gutter colours palette "
cmd([[
hi GitGutterAdd	   guifg = #009900 ctermfg = 2
hi GitGutterChange guifg = #bbbb00 ctermfg = 3
hi GitGutterDelete guifg = #ff2222 ctermfg = 1
]])

require 'cmp'.setup {}

require 'lspsaga'.init_lsp_saga {}

require'nvim-tree'.setup {
	filters = {
		custom = {
			node_modules,
			venv
		}
	}
}

require'colorizer'.setup(
	{'*';},
	{
		RGB		 = true;	-- #RGB hex codes
		RRGGBB	 = true;	-- #RRGGBB hex codes
		names	 = true;	-- "Name" codes like Blue
		RRGGBBAA = true;	-- #RRGGBBAA hex codes
		rgb_fn	 = true;	-- CSS rgb() and rgba() functions
		hsl_fn	 = true;	-- CSS hsl() and hsla() functions
		css		 = true;	-- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
		css_fn	 = true;	-- Enable all CSS *functions*: rgb_fn, hsl_fn
	})

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Key mapping config "
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- set leader key to space"
g.mapleader = ' '

map('n', '<C-s>', ':w<CR>')
map('n', '<C-F4>', ':q!<CR>')
-- F28 Is CTRL F4 in Linux : LPT You can type key code in insert mode !
map('n', '<F28>', ':q!<CR>')

-- M is the ALT modifier key
map('n', '<M-j>', ':resize -1<CR>')
map('n', '<M-k>', ':resize +1<CR>')
map('n', '<M-h>', ':vertical resize -1<CR>')
map('n', '<M-l>', ':vertical resize +1<CR>')

-- Better window movement
map('n', '<C-h>', '<C-w>h<CR>')
map('n', '<C-j>', '<C-w>j<CR>')
map('n', '<C-k>', '<C-w>k<CR>')
map('n', '<C-l>', '<C-w>l<CR>')

-- Fix terminal exit button
map('t', '<Esc>', '<C-\\><C-n>')

-- Clear the highlighting of :set hlsearch
map('n', '<C-m>', ':nohlsearch<C-R>=has("diff")?"<Bar>diffupdate":""<CR><CR><C-L>')

-- Disable the suspend signal
map('n', '<C-z>', '<Nop>')

-- Better tabbing
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Telescope keybinds
map('n', '<C-p>',	   ':Telescope find_files<CR>')
map('n', '<leader>f', ':Telescope live_grep<CR>')
map('n', '<leader>h', ':Telescope help_tags<CR>')
map('n', '<leader>c', ':Telescope commands<CR>')

-- Open the nerd tree explorer
map('n', '<C-b>', '<cmd>NvimTreeToggle<CR>')

