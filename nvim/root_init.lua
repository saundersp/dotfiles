--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global shortcuts/helper
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function map(mode, key, action, desc, buffer)
	if type(key) == 'table' then
		for _,e in ipairs(key) do
			map(mode, e, action, desc, buffer)
		end
	else
		vim.keymap.set(mode, key, action, { silent = true, buffer = buffer, desc = desc })
	end
end
local function nmap(key, action, desc, buffer) map('n', key, action, desc, buffer) end
local function vmap(key, action, desc, buffer) map('v', key, action, desc, buffer) end
local function Autocmd(events, pattern, callback)
	vim.api.nvim_create_autocmd(events, { pattern = pattern, callback = callback })
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- General settings configuration
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vim.cmd.colorscheme				('desert')									-- Set the colour scheme to a more readable one
vim.o.syntax					= true										-- Enables syntax highlighting
vim.o.listchars					= 'eol:󰌑,tab:󰌒 ,trail:•,extends:,precedes:,space:·,nbsp:󱁐'			-- List of whitespace characters replacement (see :h listchars) (using: nf-md-keyboard_return nf-md-keyboard_tab Bullet nf-cod-chevron_right nf-cod-chevron_left Interpunct nf-md-keyboard_space)
vim.o.list					= true										-- Enable replacement of listchars
vim.o.wrap					= false										-- Display long lines as just one line
vim.o.fileencoding				= 'UTF-8'									-- The encoding written to file
vim.o.iskeyword					= vim.o.iskeyword .. ',-'							-- treat dash separated words as a word text object
vim.o.tabstop					= 8										-- Set the width of a tab
vim.o.shiftwidth				= 8										-- Change the number of space characters inserted for indentation
vim.o.softtabstop				= 8										-- Change the number of space characters inserted for indentation
vim.o.smartindent				= true										-- Does smart autoindenting when starting a new line
vim.o.number					= true										-- Line numbers
vim.o.relativenumber				= true										-- Relative number (enabled after number for hybrid mode)
vim.o.cursorline				= true										-- Enable highlighting of the current line
vim.o.cursorcolumn				= true										-- Enable highlighting of the current column
vim.o.showtabline				= 2										-- Always show top files tabs
vim.o.showmode					= false										-- We don't need to see things like -- INSERT -- any more
vim.o.foldlevel					= 99										-- Fold are open when you first open a file
vim.o.visualbell				= true										-- Disable bell noise
vim.o.splitbelow				= true										-- Horizontal splits will automatically be below
vim.o.splitright				= true										-- Vertical splits will automatically be to the right
vim.o.completeopt				= 'menuone,noselect'								-- Add LSP complete popup menu
vim.o.signcolumn				= 'yes'										-- Always draw the signcolumn with 1 fixed space width
vim.o.title					= true										-- Change the window's title to the opened file name and directory
vim.o.updatetime				= 200										-- Time before CursorHold triggers
vim.o.swapfile					= false										-- Disable swapfile usage
vim.o.wildmode					= 'longest,list,full'								-- Enable autocompletion in COMMAND mode
vim.o.formatoptions				= vim.o.formatoptions .. 'r'							-- Add asterisks in block comments
vim.o.wildignore				= '*.o,*.obj,*/node_modules/*,*/.git/*,*/venv/*,*/package-lock.json'		-- Ignore files in fuzzy finder
vim.o.undofile					= true										-- Enable undofile to save undos after exit
vim.o.scrolloff					= 8										-- Minimal number of screen lines to keep above and below the cursor.
Autocmd('Filetype', 'tex',			function() vim.o.wrap = true end)						-- Enable wraping only for LaTeX files
Autocmd('Filetype', 'python',			function() vim.o.expandtab = false end)						-- Disable the tab expansion of spaces
Autocmd({ 'BufRead', 'BufNewFile' }, '*.tex',	function() vim.o.filetype = 'tex' end)						-- Sometimes LaTeX isn't properly recognized

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Key mapping configuration
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
nmap('<C-s>', '<cmd>w<CR>',													   'Save buffer shortcut')
nmap({ '<C-F4>', '<F28>' }, '<cmd>tabclose!<CR>',										   'Close tab shortcut (keeps buffer open)')
nmap({ '<S-F4>', '<F16>' }, '<cmd>bd<CR>',											   'Close buffer shortcut')
nmap('<M-j>', '<cmd>resize -1<CR>',												   'Decrease buffer window horizontal size (M is the ALT modifier key)')
nmap('<M-k>', '<cmd>resize +1<CR>',												   'Increase buffer window horizontal size (M is the ALT modifier key)')
nmap('<M-h>', '<cmd>vertical resize -1<CR>',											   'Decrease buffer window vertical size (M is the ALT modifier key)')
nmap('<M-l>', '<cmd>vertical resize +1<CR>',											   'Increase buffer window vertical size (M is the ALT modifier key)')
map('t', '<Esc>', '<C-\\><C-n>',												   'Fix terminal exit button')
nmap({'<C-m>', '<CR>'}, '<cmd>noh<CR>',												   'Clear the highlighting of :set hlsearch (<C-M> == <CR> in st)')
nmap('<C-z>', '<Nop>',														   'Disable the suspend signal')
vmap('<', '<gv',														   'Shift the selection one indent to the right')
vmap('>', '>gv',														   'Shift the selection one indent to the left')
nmap('<F2>', '<cmd>set invpaste paste?<CR>',											   'Toggle clipboard pasting')
nmap('<C-J>', 'ddp',														   'Move the current line down')
nmap('<C-K>', 'ddkkp',														   'Move the current line up')
nmap('gb', '<cmd>bnext<CR>',													   'Go to the next buffer in buffer list')
nmap('gB', '<cmd>bprevious<CR>',												   'Go to the previous buffer in buffer list')
nmap('J', 'mzJ`z',														   'Keep the cursor at the same position when joining lines')
vmap('<C-J>', "<cmd>m '>+1<CR>gv=gv",												   'Move the selected block downwards while keeping target indentation')
vmap('<C-K>', "<cmd>m '<0<CR>gv=gv",												   'Move the selected block upwards while keeping target indentation')
nmap('<C-u>', '<C-u>zz',													   'Scroll window upwards in the buffer while keeping cursor at the middle of the window')
nmap('<C-d>', '<C-d>zz',													   'Scroll window downwards in the buffer while keeping cursor at the middle of the window')
nmap('<C-f>', '<C-f>zz',													   'Scroll window downwards in the buffer while keeping cursor at the middle of the window')
nmap('<leader>fx', '<cmd>!chmod +x %<CR>',											   'Make the current file executable')
nmap('<leader>fX', '<cmd>!chmod -x %<CR>',											   'Make the current file non executable')
vim.api.nvim_create_user_command('EditConfig', 'e $MYVIMRC', { desc =								   'Edit Neovim config file' })
