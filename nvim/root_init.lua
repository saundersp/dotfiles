--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global helper functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Create a keybinding
---@see vim.keymap.set
---@param mode string|string[] mode when the keybind is detected
---@param key string|string[] key or key aliases to bind
---@param action function|string callback of the keybind
---@param desc string Description of the keybind
local function map(mode, key, action, desc)
	if type(key) == 'table' then
		for _, e in ipairs(key) do
			map(mode, e, action, desc)
		end
	else
		vim.keymap.set(mode, key, action, { silent = true, desc = desc })
	end
end
--- Create a keybinding in normal mode
---@see vim.keymap.set
---@see map
---@param key string|string[] key or key aliases to bind
---@param action function|string callback of the keybind
---@param desc string Description of the keybind
local function nmap(key, action, desc) map('n', key, action, desc) end
--- Create a keybinding in visual mode
---@see vim.keymap.set
---@see map
---@param key string|string[] key or key aliases to bind
---@param action function|string callback of the keybind
---@param desc string Description of the keybind
local function vmap(key, action, desc) map('v', key, action, desc) end

--- Create an automatic callback when a Neovim event occur
---@see vim.api.nvim_create_autocmd
---@param events string|string[] EventType
---@param pattern string|string[] pattern of the event type
---@param callback function|string callback to execute when the pattern is recognized
---@param desc string Description of the callback
local function Autocmd(events, pattern, callback, desc)
	vim.api.nvim_create_autocmd(events, { pattern = pattern, callback = callback, desc = desc })
end

--- Create a user command usable in command mode
---@see vim.api.nvim_create_user_command
---@param cmd string Name of the command
---@param fnc function|string Function to callback
---@param desc string Description of the command
---@param nargs number|nil Number of arguments needed (default = 0)
local function create_cmd(cmd, fnc, desc, nargs)
	vim.api.nvim_create_user_command(cmd, fnc, { nargs = nargs or 0, desc = desc })
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- General settings configuration
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vim.cmd.colorscheme				('desert')									-- Set the colour scheme to a more readable one
vim.o.listchars					= 'eol:󰌑,tab:󰌒 ,trail:•,extends:,precedes:,space:·,nbsp:󱁐'			-- List of whitespace characters replacement (see :h listchars) (using: nf-md-keyboard_return nf-md-keyboard_tab Bullet nf-cod-chevron_right nf-cod-chevron_left Interpunct nf-md-keyboard_space)
vim.wo.list					= true										-- Enable replacement of listchars
vim.wo.wrap					= false										-- Display long lines as just one line
vim.bo.fileencoding				= 'UTF-8'									-- The encoding written to file
vim.bo.iskeyword				= vim.bo.iskeyword .. ',-'							-- treat dash separated words as a word text object
vim.bo.tabstop					= 8										-- Set the width of a tab
vim.bo.shiftwidth				= 8										-- Change the number of space characters inserted for indentation
vim.bo.softtabstop				= 8										-- Change the number of space characters inserted for indentation
vim.bo.smartindent				= true										-- Does smart autoindenting when starting a new line
vim.wo.number					= true										-- Line numbers
vim.wo.relativenumber				= true										-- Relative number (enabled after number for hybrid mode)
vim.wo.cursorline				= true										-- Enable highlighting of the current line
vim.wo.cursorcolumn				= true										-- Enable highlighting of the current column
vim.o.showtabline				= 2										-- Always show top files tabs
vim.wo.foldlevel				= 99										-- Fold are open when you first open a file
vim.o.visualbell				= true										-- Disable bell noise
vim.o.splitbelow				= true										-- Horizontal splits will automatically be below
vim.o.splitright				= true										-- Vertical splits will automatically be to the right
vim.o.completeopt				= 'menuone,noselect'								-- Add LSP complete popup menu
vim.wo.signcolumn				= 'yes:1'									-- Draw the signcolumn with 1 fixed space width
vim.o.title					= true										-- Change the window's title to the opened file name and directory
vim.o.updatetime				= 200										-- Time before CursorHold triggers
vim.bo.swapfile					= false										-- Disable swapfile usage
vim.o.wildmode					= 'longest,list,full'								-- Enable autocompletion in COMMAND mode
vim.bo.formatoptions				= vim.o.formatoptions .. 'r'							-- Add asterisks in block comments
vim.o.wildignore				= '*.o,*.obj,*/node_modules/*,*/.git/*,*/.venv/*,*/package-lock.json'		-- Ignore files in fuzzy finder
vim.bo.undofile					= true										-- Enable undofile to save undo operations after exit
vim.o.scrolloff					= 8										-- Minimal number of screen lines to keep above and below the cursor.
Autocmd('Filetype', { 'plaintex', 'tex' },	function() vim.o.wrap = true end,						   'Enable wrapping only for LaTeX files')
Autocmd('Filetype', 'python',			function() vim.o.expandtab = false end,						   'Disable the tab expansion of spaces')

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Key mapping configuration
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
nmap('<C-s>', '<cmd>w<CR>',													   'Save buffer shortcut')
nmap({ '<C-F4>', '<F28>' }, '<cmd>tabclose!<CR>',										   'Close tab shortcut (keeps buffer open)')
nmap('<C-S-h>', '<cmd>-tabmove<CR>',												   'Move the current tab to the left')
nmap('<C-S-l>', '<cmd>+tabmove<CR>',												   'Move the current tab to the right')
nmap({ '<S-F4>', '<F16>' }, '<cmd>bd<CR>',											   'Close buffer shortcut')
nmap('<M-j>', '<cmd>resize -1<CR>',												   'Decrease buffer window horizontal size (M is the ALT modifier key)')
nmap('<M-k>', '<cmd>resize +1<CR>',												   'Increase buffer window horizontal size (M is the ALT modifier key)')
nmap('<M-h>', '<cmd>vertical resize -1<CR>',											   'Decrease buffer window vertical size (M is the ALT modifier key)')
nmap('<M-l>', '<cmd>vertical resize +1<CR>',											   'Increase buffer window vertical size (M is the ALT modifier key)')
map('t', '<Esc>', '<C-\\><C-n>',												   'Fix terminal exit button')
nmap({ '<C-m>', '<CR>' }, '<cmd>noh<CR>',											   'Clear the highlighting of :set hlsearch (<C-M> == <CR> in st)')
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
create_cmd('Settings', 'e $MYVIMRC', 												   'Edit Neovim config file')
