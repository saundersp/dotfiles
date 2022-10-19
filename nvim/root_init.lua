--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global shortcuts/helper
--------------------------------------------------------------------------------------------------------------------------------------------------------
cmd = vim.cmd
o = vim.o
b = vim.b
wo = vim.wo
g = vim.g

function Map(mode, shortcut, command)
	vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = false, silent = true })
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- General settings config
--------------------------------------------------------------------------------------------------------------------------------------------------------
--
cmd("colorscheme			delek")							-- Set the colour scheme to codedark (VSCode's dark+)
o.syntax				= true								-- Enables syntax highlighting
o.listchars				= 'eol:﬋,tab:→ ,trail:•,extends:>,precedes:<,space:·,nbsp:ﴔ'	-- List of whitespace characters replacement (see :h listchars)
o.list					= true								-- Enable replacement of listchars
o.hidden				= true								-- Required to keep multiple buffers open multiple buffers
o.wrap					= false								-- Display long lines as just one line
o.encoding				= 'UTF-8'							-- The encoding displayed
o.fileencoding				= 'UTF-8'							-- The encoding written to file
o.ruler					= true								-- Show the cursor position all the time
cmd("set iskeyword			+=-")								-- treat dash separated words as a word text object
o.tabstop				= 8								-- Set the width of a tab
o.shiftwidth				= 8								-- Change the number of space characters inserted for indentation
o.smartindent				= true								-- Does smart autoindenting when starting a new line
o.expandtab				= false								-- Disable the tab expansion of spaces
o.number				= true								-- Line numbers
o.relativenumber			= true								-- Relative number (enabled after number for hybrid mode)
o.cursorline				= true								-- Enable highlighting of the current line
o.showtabline				= 2								-- Always show top files tabs
o.showmode				= false								-- We don't need to see things like -- INSERT -- any more
o.foldmethod				= 'syntax'							-- Change the folding method to fold from { [ ...
o.foldlevel				= 99								-- Fold are open when you first open a file
o.visualbell				= true								-- Disable bell noise
o.splitbelow				= true								-- Horizontal splits will automatically be below
o.splitright				= true								-- Vertical splits will automatically be to the right
o.completeopt				= "menu,menuone,noselect"					-- Add LSP complete popup menu
o.signcolumn				= "yes"								-- Always draw the signcolumn with 1 fixed space width
o.swapfile				= false								-- Disable swapfile usage
cmd("set formatoptions			+=r")								-- Add asterisks in block comments
cmd("set wildignore			+=*/node_modules/*,*/.git/*,*/venv/*,*/package-lock.json")	-- Ignore files in fuzzy finder
cmd("autocmd FileType python set	noexpandtab")							-- Force disable expandtab on python's files
cmd("autocmd FileType tex set		wrap")								-- Enable wraping only for LaTeX files

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Key mapping config
--------------------------------------------------------------------------------------------------------------------------------------------------------
Map('n', '<C-s>', ':w<CR>') 			-- Save buffer shortcut
Map('n', '<C-F4>', ':q!<CR>') 			-- Close window shortcut (keeps buffer open)
Map('n', '<F28>', '<C-F4>') 			-- F28 Is CTRL F4 in Linux : LPT You can type key code in insert mode !
Map('n', '<S-F4>', ':bd<CR>') 			-- Close buffer shortcut
Map('n', '<F16>', '<S-F4>') 			-- F16 Is Shift F4 in Linux
Map('n', '<M-j>', ':resize -1<CR>') 		-- Buffer resize shortcuts
Map('n', '<M-k>', ':resize +1<CR>') 		-- M is the ALT modifier key
Map('n', '<M-h>', ':vertical resize -1<CR>')
Map('n', '<M-l>', ':vertical resize +1<CR>')
Map('t', '<Esc>', '<C-\\><C-n>') 		-- Fix terminal exit button
Map('n', '<C-m>', ':noh<CR>') 			-- Clear the highlighting of :set hlsearch
Map('n', '<CR>', ':noh<CR>') 			-- <C-M> == <CR> in st
Map('n', '<C-z>', '<Nop>') 			-- Disable the suspend signal
Map('v', '<', '<gv') 				-- Better tabbing
Map('v', '>', '>gv')
Map('n', '<F2>', ':set invpaste paste?<CR>')	-- Toggle clipboard pasting

