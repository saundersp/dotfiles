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
-- Plugin enabler
--------------------------------------------------------------------------------------------------------------------------------------------------------
cmd("packadd packer.nvim")
-- TODO use PackerCompile if changed
require('packer').startup(function(use)
	-- Plugin/Package management
	use { 'wbthomason/packer.nvim', opt = true }
	-- Install the vscode's codedark theme
	use { 'tomasiser/vim-code-dark', opt = true }
	-- Add a fancy bottom bar with details
	use { 'nvim-lualine/lualine.nvim',
		config = function()
			require('lualine').setup {
				options = {
					theme = 'codedark',
					disabled_filetypes = { 'NvimTree' }
				}
			}
		end,
		requires = 'kyazdani42/nvim-web-devicons'
	}
	-- Add the left column indicating git line status and preview window
	use {'lewis6991/gitsigns.nvim',
		config = function()
			require('gitsigns').setup {
				keymaps = {
					['n <leader>hp'] = '<cmd>Gitsigns preview_hunk<CR>',
					['n <leader>hU'] = '<cmd>Gitsigns reset_hunk<CR>',
					['n <leader>hs'] = '<cmd>Gitsigns stage_hunk<CR>',
					['n <leader>hu'] = '<cmd>Gitsigns undo_stage_hunk<CR>',
					['n <leader>hd'] = '<cmd>Gitsigns diffthis<CR>',
					['n [h'] = '<cmd>Gitsigns prev_hunk<CR><leader>hp',
					['n ]h'] = '<cmd>Gitsigns next_hunk<CR><leader>hp'
				},
				current_line_blame = true
			}
			-- Configure the git colours palette
			cmd([[
			hi GitSignsAdd    guifg = #009900
			hi GitSignsChange guifg = #bbbb00
			hi GitSignsDelete guifg = #ff2222
			]])
		end,
		requires = 'nvim-lua/plenary.nvim'
	}
	-- Colourize RGB codes to it designated colour
	use { 'norcalli/nvim-colorizer.lua',
		config = function()
			require'colorizer'.setup(
				{'*';},
				{
					RRGGBBAA = true,	-- #RRGGBBAA hex codes
					rgb_fn	 = true,	-- CSS rgb() and rgba() functions
					hsl_fn	 = true,	-- CSS hsl() and hsla() functions
					css	 = true,	-- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
					css_fn	 = true		-- Enable all CSS *functions*: rgb_fn, hsl_fn
				}
			)
		end
	}
	-- Quickly surround word with given symbol
	use 'tpope/vim-surround'
	-- Add fuzzy finder to files, command and more
	use {'nvim-telescope/telescope.nvim',
		config = function()
			Map('n', '<C-p>', ':Telescope find_files<CR>')
			Map('n', '<leader>ff', ':Telescope live_grep<CR>')
			Map('n', '<leader>f*', ':Telescope grep_string<CR>')
			Map('n', '<leader>ft', ':Telescope help_tags<CR>')
			Map('n', '<leader>fc', ':Telescope commands<CR>')
			Map('n', '<leader>fb', ':Telescope buffers<CR>')
			Map('n', '<leader>fm', ':Telescope marks<CR>')
			Map('n', '<leader>fk', ':Telescope keymaps<CR>')
			Map('n', '<leader>fr', ':Telescope registers<CR>')
		end,
		requires = {
			'nvim-lua/plenary.nvim',
			'kyazdani42/nvim-web-devicons'
		}
	}
	-- Automatic pairs of ( [ { insertion
	use { 'windwp/nvim-autopairs', config = function() require("nvim-autopairs").setup{} end }
	-- Add a fancy file explorer
	use {'kyazdani42/nvim-tree.lua',
		config = function()
			require'nvim-tree'.setup {
				filters = {
					custom = {
						".git",
						"node_modules",
						"venv",
						"package-lock.json"
					}
				},
				sync_root_with_cwd = true,
				view = {
					mappings = {
						list = {
							{ key = "è", action = "cd" }
						}
					}
				},
				actions = {
					open_file = {
						quit_on_open = true,
					}
				}
			}

			-- Open the nerd tree explorer
			Map('n', '<C-n>', '<cmd>NvimTreeToggle<CR>')
		end,
		requires = 'kyazdani42/nvim-web-devicons'
	}
	-- add the vmap gl<SYMBOL> to vertical align to the given symbol
	use { 'tommcdo/vim-lion',
		config = function()
			g.lion_squeeze_spaces = 1	-- Squeeze extra spaces when doing a vertical alignment
		end
	}
	-- Colourize multiple inner level to ( [ {
	use { 'luochen1990/rainbow',
		config = function()
			g.rainbow_active = 1 -- Enable rainbow plugin
		end
	}
	-- Automatic white spaces trimming
	use { 'ntpeters/vim-better-whitespace',
		config = function()
			g.better_whitespace_enabled	= 1	-- Enable the plugin
			g.strip_whitespace_on_save	= 1	-- Remove trailing white spaces on save
			g.strip_whitespace_confirm	= 0	-- Disable the confirmation message on stripping white spaces
		end
	}
	-- CSV file handling
	use { 'chrisbra/csv.vim',
		config = function()
			b.csv_arrange_align = 'lc.'	-- Left align when using ArrangeColumn in a csv file
		end
	}
	-- LSP Functionnalities}
	use {'neoclide/coc.nvim',
		branch = 'release',
		config = function()
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
			Map('n', '<leader>vd', ':CocList diagnostics<CR>')
			Map('n', '<leader>vo', ':CocOutline<CR>')
			Map('n', '<leader>vc', ':CocCommand<CR>')
			Map('n', '<leader>ve', ':CocList extensions<CR>')

			cmd([[
			function! s:show_documentation()
				if (index(['vim','help'], &filetype) >= 0)
					execute 'h '.expand('<cword>')
				elseif (coc#rpc#ready())
					call CocActionAsync('doHover')
				else
					execute '!' . &keywordprg . " " . expand('<cword>')
				endif
			endfunction

			" inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
			" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

			inoremap <silent><expr> <TAB>
				\ coc#pum#visible() ? coc#pum#next(1):
				\ CheckBackspace() ? "\<Tab>" :
				\ coc#refresh()
			inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

			" Make <CR> to accept selected completion item or notify coc.nvim to format
			" <C-g>u breaks current undo, please make your own choice.
			inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
						      \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

			function! CheckBackspace() abort
			  let col = col('.') - 1
			  return !col || getline('.')[col - 1]  =~# '\s'
			endfunction

			" Use K to show documentation in preview window
			nnoremap <silent> K :call <SID>show_documentation()<CR>

			" Highlight the symbol and its references when holding the cursor.
			autocmd CursorHold * silent call CocActionAsync('highlight')"

			" Add `:Format` command to format current buffer.
			command! -nargs=0 Format :call CocActionAsync('format')

			" Add `:Fold` command to fold current buffer.
			command! -nargs=? Fold :call CocAction('fold', <f-args>)

			" Add `:OR` command for organize imports of the current buffer.
			command! -nargs=0 OR :call CocActionAsync('runCommand', 'editor.action.organizeImport')
			]])

			g.coc_global_extensions = { "coc-cspell-dicts", "coc-spell-checker", "coc-json", "coc-pyright", "coc-lua", "coc-prettier",
				"coc-docker", "coc-java", "coc-sh", "coc-markdownlint", "coc-markdown-preview-enhanced", "coc-webview", "coc-texlab" }
		end
	}
	-- Allow use of background jobs
	use { 'tpope/vim-dispatch',
		config = function()
			cmd("autocmd FileType tex autocmd BufWritePost <buffer> :Spawn! make") -- Auto compile LaTeX document on save
			Map('n', '<leader>tp', ':Dispatch! make preview<CR>')

			-- TUI programs
			Map('n', '<leader>$g', ':Start lazygit<CR>')
			Map('n', '<leader>$d', ':Start lazydocker<CR>')
		end
	}
	-- Arduino commands
 	use { 'stevearc/vim-arduino',
		config = function()
			Map('n', '<leader>aa', ':ArduinoAttach<CR>')
			Map('n', '<leader>am', ':ArduinoVerify<CR>')
			Map('n', '<leader>au', ':ArduinoUpload<CR>')
			Map('n', '<leader>ad', ':ArduinoUploadAndSerial<CR>')
			Map('n', '<leader>ab', ':ArduinoChooseBoard<CR>')
			Map('n', '<leader>ap', ':ArduinoChooseProgrammer<CR>')
			Map('n', '<leader>as', ':ArduinoSerial<CR>')
		end
	}
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- General settings config
--------------------------------------------------------------------------------------------------------------------------------------------------------
wo.t_Co					= "256"								-- Support 256 colours
wo.t_ut					= ""								-- Reset the value to apply colorscheme
cmd("colorscheme			codedark")							-- Set the colour scheme to codedark (VSCode's dark+)
o.termguicolors				= true								-- Enable 24-bit RGB colours in the terminal
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
o.clipboard				= 'unnamedplus'							-- Copy paste between vim and everything else
o.foldmethod				= 'syntax'							-- Change the folding method to fold from { [ ...
o.foldlevel				= 99								-- Fold are open when you first open a file
o.visualbell				= true								-- Disable bell noise
o.splitbelow				= true								-- Horizontal splits will automatically be below
o.splitright				= true								-- Vertical splits will automatically be to the right
o.completeopt				= "menu,menuone,noselect"					-- Add LSP complete popup menu
o.signcolumn				= "yes"								-- Always draw the signcolumn with 1 fixed space width
o.title					= true								-- Change the window's title to the opened file name and directory
o.updatetime				= 200								-- Time before CursorHold triggers
o.swapfile				= false								-- Disable swapfile usage
cmd("set formatoptions			+=r")								-- Add asterisks in block comments
cmd("set wildignore			+=*/node_modules/*,*/.git/*,*/venv/*,*/package-lock.json")	-- Ignore files in fuzzy finder
cmd("autocmd FileType python set	noexpandtab")							-- Force disable expandtab on python's files
cmd("autocmd FileType tex set		wrap")								-- Enable wraping only for LaTeX files

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Key mapping config
--------------------------------------------------------------------------------------------------------------------------------------------------------
g.mapleader = ' ' 				-- set leader key to space
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

