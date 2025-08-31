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

--- Split a given string to a list
---@param str string String to split
---@return string[] list splitted string
---@nodiscard
local function str_to_list(str)
	local list = {}
	for token in string.gmatch(str, '[^%c]+') do
		table.insert(list, token)
	end
	return list
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Plugin enabler
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
	local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', 'https://github.com/folke/lazy.nvim.git', lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({ { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' }, { out, 'WarningMsg' }, { '\nPress any key to exit...' } }, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key to space
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local lazy_plugins = {
	-- Neovim/Vim color scheme inspired by Dark+ and Light+ theme in Visual Studio Code
	{ 'Mofiqul/vscode.nvim', init = function() require('vscode').load() end },
	-- Add a fancy bottom bar with details
	{ 'nvim-lualine/lualine.nvim',
		event = 'UIEnter',
		opts = {
			options = {
				disabled_filetypes = { statusline = { 'snacks_dashboard' } }
			},
			sections = {
				lualine_x = {
					{
						-- NOTE: Removes warning about not properly documented 'get' field
						---@diagnostic disable-next-line: undefined-field
						function() return require('noice').api.status.mode.get() end,
						-- NOTE: Removes warning about not properly documented 'has' field
						---@diagnostic disable-next-line: undefined-field
						cond = function() return package.loaded['noice'] and require('noice').api.status.mode.has() end,
						color = { gui = 'bold' }
					},
					{ 'selectioncount', color = { gui = 'bold' } }
				}
			}
		},
		dependencies = {
			-- Provides nerd fonts icons
			'nvim-tree/nvim-web-devicons',
			-- Completely replaces the UI for messages, cmdline and the popupmenu
			'folke/noice.nvim'
		}
	},
	-- Add the left column indicating git line status and preview window
	{ 'lewis6991/gitsigns.nvim',
		event = 'VeryLazy',
		config = function()
			local gs = require('gitsigns')
			gs.setup({})
			require('scrollbar.handlers.gitsigns').setup()
			nmap(']c', function() if vim.wo.diff then vim.cmd.normal({ ']c', bang = true }) else gs.nav_hunk('next') end end, 'Next Hunk (or change)')
			nmap('[c', function() if vim.wo.diff then vim.cmd.normal({ '[c', bang = true }) else gs.nav_hunk('prev') end end, 'Previous Hunk (or change)')
		end,
		keys = {
			{ '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>',		     desc = 'Hunk preview' },
			{ '<leader>hR', '<cmd>Gitsigns reset_hunk<CR>', mode = { 'n', 'v' }, desc = 'Hunk reset' },
			{ '<leader>hs', '<cmd>Gitsigns stage_hunk<CR>', mode = { 'n', 'v' }, desc = 'Hunk stage' },
			{ '<leader>hu', '<cmd>Gitsigns undo_stage_hunk<CR>',		     desc = 'Hunk undo' },
			{ '<leader>hd', '<cmd>Gitsigns diffthis<CR>',			     desc = 'Hunk diff this' },
			{ '<leader>hb', '<cmd>Gitsigns toggle_current_line_blame<CR>',	     desc = 'Hunk toggle line blame' }
		},
		cmd = 'Gitsigns',
		dependencies = {
			-- Lua library functions
			'nvim-lua/plenary.nvim',
			-- Add an extensible scrollbar
			'petertriho/nvim-scrollbar'
		}
	},
	-- Colourize RGB codes to it designated colour and add a colour picker
	{ 'uga-rosa/ccc.nvim',
		event = 'BufReadPost',
		opts = { highlighter = { auto_enable = true } },
		keys = {
			{ '<leader>cp', '<cmd>CccPick<CR>',		  desc = 'open Colour Picker' },
			{ '<leader>cc', '<cmd>CccConvert<CR>',		  desc = 'Colour Convert' },
			{ '<leader>ct', '<cmd>CccHighlighterToggle<CR>',  desc = 'Colour highlight Toggle' },
			{ '<leader>ce', '<cmd>CccHighlighterEnable<CR>',  desc = 'Colour highlight Enable' },
			{ '<leader>cd', '<cmd>CccHighlighterDisable<CR>', desc = 'Colour highlight Disable' }
		},
		cmd = { 'CccPick', 'CccConvert', 'CccHighlighterEnable', 'CccHighlighterDisable', 'CccHighlighterToggle' }
	},
	-- Quickly surround word with given symbol
	{ 'kylechui/nvim-surround', event = 'VeryLazy', config = true },
	-- Add fuzzy finder to files, command and more
	{ 'nvim-telescope/telescope.nvim',
		config = function()
			local telescope = require('telescope')
			local actions = require('telescope.actions')
			telescope.setup({
				defaults = { mappings = { i = { ['<c-d>'] = actions.delete_buffer } } },
				extensions = { ['ui-select'] = { require('telescope.themes').get_cursor({}) } }
			})
			vim.tbl_map(telescope.load_extension, { 'ui-select', 'noice' })
		end,
		keys = {
			{ '<leader>sf', '<cmd>Telescope find_files<CR>',		    desc = 'Search files' },
			{ '<leader>sF', '<cmd>Telescope git_files<CR>',			    desc = 'Search git files' },
			{ '<leader>sh', '<cmd>Telescope help_tags<CR>',			    desc = 'Search help' },
			{ '<leader>sg', '<cmd>Telescope live_grep<CR>',			    desc = 'Search by grep' },
			{ '<leader>sk', '<cmd>Telescope keymaps<CR>',			    desc = 'Search keymaps' },
			{ '<leader>sc', '<cmd>Telescope commands<CR>',			    desc = 'Search commands' },
			{ '<leader>sb', '<cmd>Telescope buffers<CR>',			    desc = 'Search buffers' },
			{ '<leader>ss', '<cmd>Telescope resume<CR>',			    desc = 'Search resume' },
			{ '<leader>st', '<cmd>TodoTelescope keywords=TODO,FIX<CR>',	    desc = 'Search todos' },
			{ '<leader>sN', '<cmd>Telescope noice<CR>',			    desc = 'Search Noice messages' },
			{ '<leader>sn', '<cmd>Telescope notify<CR>',			    desc = 'Search notifications (powered by notify)' }
		},
		cmd = 'Telescope',
		dependencies = {
			-- Bind vim.ui.select to telescope
			'nvim-telescope/telescope-ui-select.nvim',
			-- Lua library functions
			'nvim-lua/plenary.nvim',
			-- Provides nerd fonts icons
			'nvim-tree/nvim-web-devicons',
			-- Highlight todo, notes, etc in comments
			'folke/todo-comments.nvim',
			-- Completely replaces the UI for messages, cmdline and the popupmenu
			'folke/noice.nvim',
			-- A fancy, configurable, notification manager for Neovim
			'rcarriga/nvim-notify'
		}
	},
	-- Edit the filesystem like a buffer
	{ 'stevearc/oil.nvim',
		opts = { default_file_explorer = false },
		keys = { { '<C-n>', '<cmd>Oil<CR>', desc = 'Open Oil file manager' } },
		cmd = 'Oil',
		dependencies = {
			-- Provides nerd fonts icons
			'nvim-tree/nvim-web-devicons'
		}
	},
	-- Library of 40+ independent Lua modules improving overall Neovim (version 0.8 and higher) experience with minimal effort
	{ 'echasnovski/mini.nvim',
		version = false,
		event = 'VeryLazy',
		config = function()
			-- add the vmap gl<SYMBOL> to vertical align to the given symbol
			require('mini.align').setup({ mappings = { start = 'gl', start_with_preview = 'gL' } })
		end
	},
	-- Automatic white spaces trimming
	{ 'ntpeters/vim-better-whitespace',
		event = 'UIEnter',
		init = function()
			vim.g.better_whitespace_enabled = 1	-- Enable the plugin
			vim.g.strip_whitespace_on_save  = 1	-- Remove trailing white spaces on save
			vim.g.strip_whitespace_confirm  = 0	-- Disable the confirmation message on stripping white spaces
		end,
		cmd = {
			'StripWhitespace', 'EnableStripWhitespaceOnSave', 'DisableStripWhitespaceOnSave', 'ToggleStripWhitespaceOnSave',
			'EnableWhitespace', 'DisableWhitespace', 'ToggleWhitespace', 'NextTrailingWhitespace', 'PrevTrailingWhitespace'
		},
		keys = {
			{ '[w', '<cmd>PrevTrailingWhitespace<CR>', desc = 'Jump to previous whitespace' },
			{ ']w', '<cmd>NextTrailingWhitespace<CR>', desc = 'Jump to next whitespace' }
		}
	},
	-- Rainbow CSV
	{ 'cameron-wags/rainbow_csv.nvim',
		config = true,
		ft = { 'csv', 'tsv', 'csv_semicolon', 'csv_whitespace', 'csv_pipe', 'rfc_csv', 'rfc_semicolon' },
		cmd = { 'RainbowDelim', 'RainbowDelimSimple', 'RainbowDelimQuoted', 'RainbowMultiDelim' }
	},
	-- CSV better viewer
	{ 'hat0uma/csvview.nvim',
		ft = { 'csv', 'tsv', 'csv_semicolon', 'csv_whitespace', 'csv_pipe', 'rfc_csv', 'rfc_semicolon' },
		opts = { view = { display_mode = 'border' } },
		cmd = { 'CsvViewEnable', 'CsvViewDisable' }
	},
	-- Autocompletion
	{ 'hrsh7th/nvim-cmp',
		event = 'InsertEnter',
		config = function()
			local cmp = require('cmp')

			cmp.setup({
				window = {
					completion = cmp.config.window.bordered(),
					documention = cmp.config.window.bordered()
				},
				mapping = cmp.mapping.preset.insert({
					['<C-d>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>'] = cmp.mapping.abort(),
					['<CR>'] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true
					}),
					['<Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<S-Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end, { 'i', 's' })
				}),
				sources = cmp.config.sources({
					-- Buffer words
					{ name = 'buffer' }
				})
			})

			-- `/` cmdline setup.
			cmp.setup.cmdline('/', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = 'buffer' }
				}
			})

			-- `:` cmdline setup.
			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = 'path' }
				}, {
					{
						name = 'cmdline',
						option = {
							ignore_cmds = { 'Man', '!' }
						}
					}
				})
			})

			local cmp_autopairs = require('nvim-autopairs.completion.cmp')
			cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
		end,
		cmd = 'CmpStatus',
		dependencies = {
			-- Automatic pairs of ( [ { insertion
			{ 'windwp/nvim-autopairs', config = true },
			-- nvim-cmp source for buffer words
			'hrsh7th/cmp-buffer',
			-- nvim-cmp source for vim's cmdline
			'hrsh7th/cmp-cmdline'
		}
	},
	-- Allow use of background jobs
	{ 'tpope/vim-dispatch',
		keys = {
			{ '<leader>mm', '<cmd>Make -j $(nproc)<CR>',		 desc = 'Make the default recipe in cwd (multi-jobs)' },
			{ '<leader>mM', '<cmd>Make<CR>',			 desc = 'Make the default recipe in cwd' },
			{ '<leader>ms', '<cmd>Start -wait=error make start<CR>', desc = 'Make the "start" recipe in cwd' },
			{ '<leader>mt', '<cmd>Start -wait=always make test<CR>', desc = 'Make the "test" recipe in cwd' },
			{ '<leader>mc', '<cmd>Make clean<CR>',			 desc = 'Make the "clean" recipe in cwd' },
			{ '<leader>mC', '<cmd>Make mrproper<CR>',		 desc = 'Make the "mrproper" recipe in cwd' },
			{ '<leader>md', '<cmd>Start docker compose build<CR>',	 desc = 'Build all "docker" compose tag in cwd' }
		},
		cmd = { 'Dispatch', 'Make', 'Focus', 'Start', 'Spawn' }
	},
	-- Highlight, edit, and navigate code
	{ 'nvim-treesitter/nvim-treesitter',
		event = 'BufReadPost',
		config = function()
			require('nvim-treesitter.configs').setup({
				-- Add languages to be installed here that you want installed for treesitter
				ensure_installed = {
					'bash', 'c', 'cpp', 'cuda', 'diff', 'haskell', 'html', 'javascript',
					'jsdoc', 'json', 'jsonc', 'lua', 'luadoc', 'luap', 'markdown_inline',
					'python', 'query', 'regex', 'toml', 'tsx', 'typescript', 'vim',
					'vimdoc', 'xml', 'yaml', 'typst', 'http',
					-- Requires tree-sitter-cli
					'latex'
				},
				highlight = { enable = true },
				modules = {},
				ignore_install = {},
				sync_install = false,
				auto_install = false
			})
		end,
		cmd = {
			'TSBufDisable', 'TSBufEnable', 'TSBufToggle', 'TSConfigInfo', 'TSDisable', 'TSEditQuery',
			'TSEditQueryUserAfter', 'TSEnable', 'TSInstall', 'TSInstallFromGrammar', 'TSInstallInfo',
			'TSInstallSync', 'TSModuleInfo', 'TSToggle', 'TSUninstall', 'TSUpdate', 'TSUpdateSync'
		}
	},
	-- Shows the context of the currently visible buffer contents
	{ 'nvim-treesitter/nvim-treesitter-context',
		event = 'VeryLazy',
		opts = { max_lines = 3 },
		cmd = { 'TSContextEnable', 'TSContextDisable', 'TSContextToggle' },
		dependencies = {
			-- Highlight, edit, and navigate code
			'nvim-treesitter/nvim-treesitter'
		}
	},
	-- Colourize multiple inner level to ( [ {
	{ 'HiPhish/rainbow-delimiters.nvim',
		event = 'BufReadPost',
		dependencies = {
			-- Highlight, edit, and navigate code
			'nvim-treesitter/nvim-treesitter'
		}
	},
	-- Show a togglable undotree
	{ 'mbbill/undotree',
		keys = { { '<leader>ut', '<Cmd>UndotreeToggle<CR>', desc = 'Open Undo tree' } },
		cmd = { 'UndotreeFocus', 'UndotreeHide', 'UndotreePersistUndo', 'UndotreeShow', 'UndotreeToggle' }
	},
	-- Display a popup with possible key bindings of the command you started typing
	{ 'folke/which-key.nvim',
		event = 'VeryLazy',
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 200
		end,
		opts = {
			preset = 'modern',
			spec = {
				{
					mode = { 'n', 'v' },
					{	'<leader>h',	group = 'Git' },
					{	'<leader>s',	group = 'Search' },
					{	'<leader>c',	group = 'Color picker' },
					{	'<leader>m',	group = 'Makefile scripts' },
					{	'<leader>o',	group = 'External tools' },
					{	'[',		group = 'prev' },
					{	']',		group = 'next' }
				}
			}
		},
		keys = { { '<leader>?', function() require('which-key').show({}) end, desc = 'Buffer Local Keymaps (which-key)' } },
		cmd = 'WhichKey'
	},
	-- Stylize the bufferline
	{ 'akinsho/bufferline.nvim',
		event = 'VimEnter',
		opts = { options = {
			mode = 'tabs',
			show_close_icon = false,
			show_buffer_close_icons = false
		}},
		cmd = {
			'BufferLineCloseLeft', 'BufferLineCloseOthers', 'BufferLineCloseRight',
			'BufferLineCycleNext', 'BufferLineCyclePrev', 'BufferLineGoToBuffer',
			'BufferLineGroupClose', 'BufferLineGroupToggle', 'BufferLineMoveNext',
			'BufferLineMovePrev', 'BufferLinePick', 'BufferLinePickClose',
			'BufferLineSortByDirectory', 'BufferLineSortByExtension', 'BufferLineSortByRelativeDirectory',
			'BufferLineSortByTabs', 'BufferLineTabRename', 'BufferLineTogglePin'
		},
		dependencies = {
			-- Provides nerd fonts icons
			'nvim-tree/nvim-web-devicons'
		}
	},
	-- Add an extensible scrollbar
	{ 'petertriho/nvim-scrollbar',
		event = 'VeryLazy',
		opts = {
			show_in_active_only = true,
			handlers = { gitsigns = true },
			excluded_filetypes = { 'snacks_dashboard' }
		},
		cmd = { 'ScrollbarShow', 'ScrollbarHide', 'ScrollbarToggle' },
		dependencies = {
			-- Add the left column indicating git line status and preview window
			'lewis6991/gitsigns.nvim'
		}
	},
	-- Completely replaces the UI for messages, cmdline and the popupmenu
	{ 'folke/noice.nvim',
		event = 'VeryLazy',
		init = function()
			-- Fix bad lualine
			vim.o.showmode = false
		end,
		opts = {
			routes = {{
				filter = {
					event = 'msg_show',
					any = {
						-- Hide written messages
						{ find = '%d+L, %d+B' },
						-- Hide undo messages
						{ find = '; after #%d+' },
						{ find = '; before #%d+' },
						{ find = 'Already at newest change' },
						{ find = 'Already at oldest change' },
						-- Hide deleted lines messages
						{ find = '%d fewer lines' },
						-- Hide yanked messages
						{ find = '%d lines yanked' },
						-- Hide indent messages
						{ find = '%d lines [><]ed %d time' }
					}
				},
				opts = { skip = true }
			}}
		},
		keys = {
			{ '<leader>nd', '<cmd>Noice dismiss<CR>', 'Dismiss the notifications' },
			{ '<leader>nl', '<cmd>Noice last<CR>',	  'Show the last notification in a popup' }
		},
		cmd = {
			'Noice', 'NoiceConfig', 'NoiceDebug', 'NoiceDisable',
			'NoiceDismiss', 'NoiceEnable', 'NoiceErrors', 'NoiceHistory',
			'NoiceLast', 'NoiceLog', 'NoiceRoutes', 'NoiceStats',
			'NoiceTelescope', 'NoiceViewstats'
		},
		dependencies = {
			-- UI Component Library for Neovim
			'MunifTanjim/nui.nvim',
			-- A fancy, configurable, notification manager for Neovim
			'rcarriga/nvim-notify'
		}
	},
	-- A fancy, configurable, notification manager for Neovim
	{ 'rcarriga/nvim-notify', opts = { background_colour = '#000000' } },
	-- Make folding look modern
	{ 'kevinhwang91/nvim-ufo',
		event = 'VeryLazy',
		opts = { provider_selector = function() return { 'treesitter', 'indent' } end },
		cmd = {
			'UfoEnable', 'UfoDisable', 'UfoInspect', 'UfoAttach',
			'UfoDetach', 'UfoEnableFold', 'UfoDisableFold'
		},
		dependencies = {
			-- Porting Promise & Async from JavaScript to Lua
			'kevinhwang91/promise-async'
		}
	},
	-- Bring automated annotation
	{ 'danymat/neogen',
		config = true,
		keys = {
			{ '<leader>ng', function() require('neogen').generate() end,			   desc = 'Generate doxygen documentation' },
			{ '<C-l>',	function() require('neogen').jump_next() end, mode = { 'n', 'i' }, desc = 'Jump to next entry of doxygen' },
			{ '<C-h>',	function() require('neogen').jump_prev() end, mode = { 'n', 'i' }, desc = 'Jump to previous entry of doxygen' }
		},
		cmd = 'Neogen',
		dependencies = {
			-- Highlight, edit, and navigate code
			'nvim-treesitter/nvim-treesitter'
		}
	},
	-- Hex editing done right
	{ 'RaafatTurki/hex.nvim',
		config = true,
		keys = { { '<leader>xt', '<cmd>HexToggle<CR>', 'Toggle between hex view and normal view' } },
		cmd = { 'HexDump', 'HexAssemble', 'HexToggle' }
	},
	-- Better navigation inside tmux
	{ 'alexghergh/nvim-tmux-navigation',
		event = 'VeryLazy',
		opts = { disable_when_zoomed = true },
		keys = {
			{ '<C-b>h', '<cmd>NvimTmuxNavigateLeft<CR>',  desc = 'Navigate to the left tmux pane if existent' },
			{ '<C-b>j', '<cmd>NvimTmuxNavigateDown<CR>',  desc = 'Navigate to the down tmux pane if existent' },
			{ '<C-b>k', '<cmd>NvimTmuxNavigateUp<CR>',    desc = 'Navigate to the up tmux pane if existent' },
			{ '<C-b>l', '<cmd>NvimTmuxNavigateRight<CR>', desc = 'Navigate to the right tmux pane if existent' }
		},
		cmd = {
			'NvimTmuxNavigateUp', 'NvimTmuxNavigateRight', 'NvimTmuxNavigateDown',
			'NvimTmuxNavigateLeft', 'NvimTmuxNavigateNext', 'NvimTmuxNavigateLastActive'
		}
	},
	-- Highlight todo, notes, etc in comments
	{ 'folke/todo-comments.nvim',
		event = 'VeryLazy',
		opts = {
			signs = false,
			highlight = { pattern = '.*<(KEYWORDS)\\s*[: ]' },
			search = { pattern = '\\b(KEYWORDS)[: ]' }
		},
		keys = {
			{ ']t', function() require('todo-comments').jump_next() end, desc = 'Next todo comment' },
			{ '[t', function() require('todo-comments').jump_prev() end, desc = 'Previous todo comment' }
		},
		cmd = { 'TodoTelescope', 'TodoQuickFix', 'TodoLocList' },
		dependencies = {
			-- Lua library functions
			'nvim-lua/plenary.nvim'
		}
	},
	-- It uses Neovim's virtual text feature and no conceal to add indentation guides to Neovim
	{ 'lukas-reineke/indent-blankline.nvim',
		main = 'ibl',
		event = 'VeryLazy',
		opts = {
			indent = { char = '│', tab_char = '│' },
			exclude = { filetypes = { 'help', 'lazy', 'mason', 'notify' } },
			scope = {
				highlight = {
					'RainbowDelimiterRed', 'RainbowDelimiterYellow',
					'RainbowDelimiterBlue', 'RainbowDelimiterOrange',
					'RainbowDelimiterGreen', 'RainbowDelimiterViolet',
					'RainbowDelimiterCyan'
				}
			}
		},
		dependencies = {
			-- Highlight, edit, and navigate code
			'nvim-treesitter/nvim-treesitter',
			-- Colourize multiple inner level to ( [ {
			'HiPhish/rainbow-delimiters.nvim'
		}
	},
	-- Navigate code with search labels, enhanced character motions and Treesitter integration
	{ 'folke/flash.nvim',
		event = 'VeryLazy',
		config = true,
		keys = {
			{ 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end,       desc = 'Flash' },
			{ 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash Treesitter' }
		}
	},
	-- 🍿 A collection of small QoL plugins for Neovim
	{ 'folke/snacks.nvim',
		event = 'BufEnter',
		opts = {
			dashboard = {
				preset = {
					header = table.concat({
						"                        ...',;;:cccccccc:;,..",
						"                    ..,;:cccc::::ccccclloooolc;'.",
						"                 .',;:::;;;;:loodxk0kkxxkxxdocccc;;'..",
						"               .,;;;,,;:coxldKNWWWMMMMWNNWWNNKkdolcccc:,.",
						"            .',;;,',;lxo:...dXWMMMMMMMMNkloOXNNNX0koc:coo;.",
						"         ..,;:;,,,:ldl'   .kWMMMWXXNWMMMMXd..':d0XWWN0d:;lkd,",
						"       ..,;;,,'':loc.     lKMMMNl. .c0KNWNK:  ..';lx00X0l,cxo,.",
						"     ..''....'cooc.       c0NMMX;   .l0XWN0;       ,ddx00occl:.",
						"   ..'..  .':odc.         .x0KKKkolcld000xc.       .cxxxkkdl:,..",
						" ..''..   ;dxolc;'         .lxx000kkxx00kc.      .;looolllol:'..",
						"..'..    .':lloolc:,..       'lxkkkkk0kd,   ..':clc:::;,,;:;,'..",
						"......   ....',;;;:ccc::;;,''',:loddol:,,;:clllolc:;;,'........",
						"    .     ....'''',,,;;:cccccclllloooollllccc:c:::;,'..",
						"            .......'',,,,,,,,;;::::ccccc::::;;;,,''...",
						"              ...............''',,,;;;,,''''''......",
						"                   ............................"
					}, '\n'),
					keys = {
						{ icon = '', key = 'e', desc = 'New file', action = ':ene' },			  -- nf-fa-file
						{ icon = '', key = 's', desc = 'Settings', action = ':Settings' },		  -- nf-fa-cog
						{ icon = '', key = 'E', desc = 'Espanso', action = ':EspansoEdit' },		  -- nf-fa-keyboard
						{ icon = '󰍉', key = 'f', desc = 'Files', action = ':Telescope find_files' },	  -- nf-md-magnify
						{ icon = '󰑑', key = 'g', desc = 'Find string', action = ':Telescope live_grep' }, -- nf-md-regex
						{ icon = '󰄬', key = 't', desc = 'Todos', action = ':TodoTelescope' },		  -- nf-md-regex
						{ icon = '', key = 'q', desc = 'Quit', action = ':qa' }			  -- nf-md-regex
					}
				},
				sections = {
					{ pane = 2, section = 'header', align = 'left' },
					{ pane = 2, title = 'The honest philosopher seeks only the truth,\neven if it bears no comfort.', align = 'center', padding = 1 },
					{ icon = '', title = 'Keymaps', section = 'keys', indent = 2, padding = 1 },
					{ icon = '', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 1 },
					{ icon = '', title = 'Projects', section = 'projects', indent = 2, padding = 1 },
					{ section = 'startup' }
				}
			},
			lazygit = {}
		},
		keys = {
			{ '<leader>og', function() require('snacks').lazygit() end,		 desc = 'Open Lazygit' },
			{ '<leader>od', function() require('snacks').terminal('lazydocker') end, desc = 'Open lazydocker' },
			{ '<leader>ob', function() require('snacks').terminal('btop') end,	 desc = 'Open btop' },
			{ '<leader>ot', function() require('snacks').terminal() end,		 desc = 'Open terminal' }
		}
	},
}

local lazy = require('lazy')
-- NOTE: Removes warning about not properly marked as optional fields
---@diagnostic disable-next-line: missing-fields
lazy.setup({
	spec = lazy_plugins,
	defaults = { lazy = true },
	rocks = { enabled = false },
	ui = {
		custom_keys = {
			['<localleader>i'] = {
				function(plug)
					local plug_config = str_to_list(vim.inspect(plug))

					require('snacks').win({
						text = plug_config,
						width = 120,
						height = math.min(40, #plug_config),
						ft = 'lua',
						border = 'rounded',
						wo = { relativenumber = true, winbar = 'Configuration of ' .. plug.name },
						bo = { buftype = 'nowrite', bufhidden = 'delete', modifiable = false }
					})
				end,
				desc = 'Inspect Plugin'
			}
		}
	}
})
nmap('<leader>lo', lazy.home,	 'Open Lazy plugin manager main menu')
nmap('<leader>lp', lazy.profile, 'Open lazy loading profiling results')

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- General settings configuration
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vim.o.termguicolors				= true										-- Enable 24-bit RGB colours in the terminal
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
vim.filetype.add({ extension = { rest = 'http' } })										-- Added custom filetype to http (REST API)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Key mapping configuration
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
nmap('<C-s>', '<cmd>w<CR>',													   'Save buffer shortcut')
nmap({ '<C-F4>', '<F28>' }, '<cmd>tabclose!<CR>',										   'Close tab shortcut (keeps buffer open)')
nmap({ '<C-S-h>', '<C-H>' }, '<cmd>-tabmove<CR>',										   'Move the current tab to the left')
nmap({ '<C-S-l>', '<C-L>' }, '<cmd>+tabmove<CR>',										   'Move the current tab to the right')
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
create_cmd('GetCmds', function(opts) vim.cmd('redir @"\ncomm ' .. opts.args .. '\nredir END\nput') end,				   'Get all the commands starting by ARG', 1)
