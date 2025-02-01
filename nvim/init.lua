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

--- Generalized transformation of a given table
---@param tbl table table desconstructable in pairs to transform
---@param predicate function(acc: any, key: string, value: any): nil callback that transform the current element in the array
---@param initial any|nil Initial value of the reduced result
---@return any result transformed result
---@nodiscard
local function reduce(tbl, predicate, initial)
	local acc = initial or {}
	for key, value in pairs(tbl) do
		predicate(acc, key, value)
	end
	return acc
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

--- Execute a given command on the system's shell
---@param cmd string Command to run
---@return string stdout of the command
local function run_cmd(cmd)
	local handler = io.popen(cmd)
	if (handler == nil) then
		print("Couldn't run specified command : " .. cmd)
		return ''
	end
	local cmd_output = handler:read('*a')
	handler:close()
	return cmd_output
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

--- Format the list of ensure_installed packages name
---@param sources table table of packages configuration
---@return string[] list_packages list of packages name
---@nodiscard
local function format_ensure_install(sources)
	local list_packages = {}
	for source_name, source in pairs(sources) do
		if source.__skip_download ~= true then
			if source.__package_name ~= nil then
				table.insert(list_packages, source.__package_name)
			else
				table.insert(list_packages, source_name)
			end
		end
	end
	return list_packages
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Plugin enabler
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
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
	-- Install the vscode's codedark theme
	{ 'ShermanDevers/codedark.nvim',
		priority = 1000,
		init = function()
			require('vscode').load()
			vim.g.colors_name = 'codedark' -- Fix lualine theme deduction
		end
	},
	-- Add a fancy bottom bar with details
	{ 'nvim-lualine/lualine.nvim',
		event = 'UIEnter',
		opts = {
			options = {
				-- Special theme keyword to automatically load theme based on colourscheme
				theme = 'auto',
				ignore_focus = {
					'dapui_watches', 'dapui_breakpoints',
					'dapui_scopes', 'dapui_console',
					'dapui_stacks', 'dap-repl'
				},
				disabled_filetypes = { statusline = { 'snacks_dashboard', 'neo-tree' } }
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
						color = { fg = '#ce9178', gui = 'bold' }
					},
					{
						'selectioncount',
						color = { fg = '#787878', gui = 'bold' }
					}
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
				extensions = {
					['ui-select'] = { require('telescope.themes').get_cursor({}) },
					media_files = { filetypes = { 'png', 'svg', 'webp', 'jpg', 'jpeg' } }
				}
			})
			vim.tbl_map(telescope.load_extension, { 'ui-select', 'noice', 'dap', 'media_files' })
		end,
		keys = {
			{ 'gr',		'<cmd>Telescope lsp_references<CR>',		    desc = 'LSP: Goto references' },
			{ '<leader>wd', '<cmd>Telescope lsp_document_symbols<CR>',	    desc = 'LSP: Document symbols' },
			{ '<leader>ws', '<cmd>Telescope lsp_dynamic_workspace_symbols<CR>', desc = 'LSP: Workspace symbols' },
			{ '<leader>sf', '<cmd>Telescope find_files<CR>',		    desc = 'Search files' },
			{ '<leader>sF', '<cmd>Telescope git_files<CR>',			    desc = 'Search git files' },
			{ '<leader>sh', '<cmd>Telescope help_tags<CR>',			    desc = 'Search help' },
			{ '<leader>sg', '<cmd>Telescope live_grep<CR>',			    desc = 'Search by grep' },
			{ '<leader>sd', '<cmd>Telescope diagnostics<CR>',		    desc = 'Search diagnostics' },
			{ '<leader>sk', '<cmd>Telescope keymaps<CR>',			    desc = 'Search keymaps' },
			{ '<leader>sc', '<cmd>Telescope commands<CR>',			    desc = 'Search commands' },
			{ '<leader>sb', '<cmd>Telescope buffers<CR>',			    desc = 'Search buffers' },
			{ '<leader>sm', '<cmd>Telescope media_files<CR>',		    desc = 'Search media files' },
			{ '<leader>ss', '<cmd>Telescope resume<CR>',			    desc = 'Search resume' },
			{ '<leader>st', '<cmd>TodoTelescope keywords=TODO,FIX<CR>',	    desc = 'Search todos' },
			{ '<leader>sN', '<cmd>Telescope noice<CR>',			    desc = 'Search Noice messages' },
			{ '<leader>sn', '<cmd>Telescope notify<CR>',			    desc = 'Search notifications (powered by notify)' },
			{ '<leader>dh', '<cmd>Telescope dap commands<CR>',		    desc = 'Dap search commands' },
			{ '<leader>dv', '<cmd>Telescope dap variables<CR>',		    desc = 'Dap search variables' },
			{ '<leader>sp', '<cmd>Telescope dap list_breakpoints<CR>',	    desc = 'Dap search breakpoints' }
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
			'rcarriga/nvim-notify',
			-- Extension to integrate nvim-dap
			'nvim-telescope/telescope-dap.nvim',
			-- LSP Configuration & Plugins
			'neovim/nvim-lspconfig',
			-- Extension to preview media files using Ueberzug
			'nvim-telescope/telescope-media-files.nvim',
			-- [WIP] Popup API from vim in Neovim (needed for telescope-media-files). Will eventually be merged upstream
			'nvim-lua/popup.nvim'
		}
	},
	-- Neovim plugin to manage the file system and other tree like structures
	{ 'nvim-neo-tree/neo-tree.nvim',
		branch = 'v3.x',
		init = function()
			-- Hijack netrw without loading plugin
			if vim.fn.argc(-1) == 1 then
				local var = vim.fn.argv(0)
				if type(var) == 'table' then
					return
				end
				local stat = vim.loop.fs_stat(var)
				if stat and stat.type == 'directory' then
					require('neo-tree')
				end
			end
		end,
		opts = {
			close_if_last_window = true,
			window = { position = 'current' },
			filesystem = {
				follow_current_file = { enabled = true },
				use_libuv_file_watcher = true
			}
		},
		keys = { { '<C-p>', '<cmd>Neotree toggle reveal<CR>', desc = 'Open Neotree file manager' } },
		cmd = 'Neotree',
		dependencies = {
			-- Lua library functions
			'nvim-lua/plenary.nvim',
			-- Provides nerd fonts icons
			'nvim-tree/nvim-web-devicons',
			-- UI Component Library for Neovim
			'MunifTanjim/nui.nvim'
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
	-- Faster LuaLS setup for Neovim
	{ 'folke/lazydev.nvim',
		ft = 'lua', -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = 'luvit-meta/library', words = { 'vim%.uv' } }
			}
		},
		dependencies = {
			-- Optional `vim.uv` typings
			{ 'Bilal2453/luvit-meta', lazy = true }
		}
	},
	-- LSP Configuration & Plugins
	{ 'neovim/nvim-lspconfig',
		event = { 'BufReadPost', 'BufNewFile' },
		init = function()
			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = '', -- nf-cod-error
						[vim.diagnostic.severity.WARN] =  '', -- nf-cod-warning
						[vim.diagnostic.severity.INFO] =  '', -- nf-cod-info
						[vim.diagnostic.severity.HINT] =  ''  -- nf-oct-light_bulb
					}
				},
				virtual_text = true
			})
		end,
		config = function()
			local lspconfig = require('lspconfig')
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

			-- Enable the following language servers with overriding configuration
			-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
			local servers = {
				lua_ls = {
					Lua = {
						runtime = { version = 'LuaJIT' },
						workspace = { checkThirdParty = false },
						completion = { callSnippet = 'Replace' },
						telemetry = { enable = false }
					}
				},
				clangd = {
					-- Install package rather than using Mason
					-- https://clangd.llvm.org/installation.html
					__skip_download = true,
					CompileFlags = {
						add = { '-I/opt/cuda/targets/x86_64-linux/include' }
					}
				},
				ts_ls = {},
				hls = {
					-- Install package rather than using Mason
					-- https://github.com/haskell/haskell-language-server
					__skip_download = true,
					filetypes = { 'haskell', 'lhaskell', 'cabal' }
				},
				cmake = {},
				bashls = {},
				pyright = {},
				texlab = {},
				docker_compose_language_service = {},
				marksman = {},
				tinymist = {},
				ltex = {
					-- Install package rather than using Mason
					__skip_download = true,
					-- LSP is handled by ltex_extra.nvim
					__skip_setup = true
				}
			}

			require('mason-lspconfig').setup({
				ensure_installed = format_ensure_install(servers),
				automatic_installation = false
			})

			for name, opts in pairs(servers) do
				if opts.__skip_setup ~= true then
					lspconfig[name].setup({
						capabilities = capabilities,
						settings = opts
					})
				end
			end
		end,
		keys = {
			{ '<leader>rn', vim.lsp.buf.rename,	     desc = 'LSP: Rename' },
			{ 'gd',		vim.lsp.buf.definition,	     desc = 'LSP: Goto definition' },
			{ 'gI',		vim.lsp.buf.implementation,  desc = 'LSP: Goto implementation' },
			{ '<leader>D',  vim.lsp.buf.type_definition, desc = 'LSP: Type definition' },
			{ 'K',		vim.lsp.buf.hover,	     desc = 'LSP: Hover documentation' },
			{ 'gK',		vim.lsp.buf.signature_help,  desc = 'LSP: Signature documentation' },
			{ 'gD',		vim.lsp.buf.declaration,     desc = 'LSP: Goto declaration' },
			{ '<leader>e',  vim.diagnostic.open_float,   desc = 'LSP: Show diagnostic error message' },
			{ '<leader>ca', function()
				if package.loaded['telescope'] == nil then require('telescope') end
				return vim.lsp.buf.code_action() end,
								     desc = 'LSP: Code action' },
			{ '[d',		vim.diagnostic.goto_prev,    desc = 'LSP: Jump to previous diagnostics' },
			{ ']d',		vim.diagnostic.goto_next,    desc = 'LSP: Jump to next diagnostics' },
			{ '<leader>q',  vim.diagnostic.setloclist,   desc = 'LSP: Open diagnostic quickfix' }
		},
		cmd = { 'LspInfo', 'LspInstall', 'LspLog', 'LspRestart', 'LspStart', 'LspStop', 'LspUninstall' },
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			'williamboman/mason.nvim', 'williamboman/mason-lspconfig.nvim',
			-- Auto completion functionalities
			'hrsh7th/cmp-nvim-lsp'
		}
	},
	-- Debugging purposes
	{ 'jay-babu/mason-nvim-dap.nvim',
		init  = function()
			vim.fn.sign_define('DapBreakpoint',	     { text = '', texthl = 'DapUIBreakpointsInfo' }) -- nf-fa-stop
			vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DapUIBreakpointsInfo' }) -- nf-cod-debug_breakpoint_conditional
			vim.fn.sign_define('DapBreakpointRejected',  { text = '', texthl = 'DapUIBreakpointsInfo' }) -- nf-fa-hand
			vim.fn.sign_define('DapLogPoint',	     { text = '', texthl = 'DapUIBreakpointsInfo' }) -- nf-cod-debug_breakpoint_log
			vim.fn.sign_define('DapStopped',	     { text = '', texthl = 'DapUIStopped' })	      -- nf-fa-circle_stop
		end,
		config = function()
			local dap = require('dap')

			dap.adapters = {
				cpptools = {
					id = 'cppdbg',
					__package_name = 'cppdbg',
					type = 'executable',
					command = 'OpenDebugAD7'
				},
				debugpy = {
					__package_name = 'python',
					type = 'executable',
					command = 'debugpy-adapter'
				}
			}

			require('mason-nvim-dap').setup({
				ensure_installed = format_ensure_install(dap.adapters),
				automatic_installation = false
			})

			local function select_exec(directory, callback)
				local pickers = require('telescope.pickers')
				local finders = require('telescope.finders')
				local actions = require('telescope.actions')
				local actions_state = require('telescope.actions.state')
				local sorter = require('telescope.config').values.generic_sorter

				local cmd_output = run_cmd('fd . --color never -t x --base-directory ' .. directory)
				if (cmd_output == nil) then
					return false
				end
				local list_files = str_to_list(cmd_output)

				pickers.new({
					prompt_title = 'Executable',
					finder = finders.new_table(list_files),
					sorter = sorter(),
					attach_mappings = function(prompt_bufnr)
						actions.select_default:replace(function()
							local selection = actions_state.get_selected_entry()
							actions.close(prompt_bufnr)
							callback(selection.value)
						end)
						return true
					end
				}, {}):find()
				return true
			end

			local default_c_config
			default_c_config = {
				name = 'Launch file',
				type = 'cpptools',
				request = 'launch',
				program = function()
					local cwd = './'
					if vim.fn.isdirectory('./bin') == 1 then
						cwd = './bin/'
					elseif vim.fn.isdirectory('./build') == 1 then
						cwd = './build/'
					end

					default_c_config.cwd = '${workspaceFolder}/' .. cwd

					local co = coroutine.running()
					local executable = nil
					select_exec(cwd, function(selection)
						executable = default_c_config.cwd .. selection
						coroutine.resume(co)
					end)

					coroutine.yield()
					return executable
				end,
				cwd = '${workspaceFolder}'
			}

			dap.configurations = {
				c = { default_c_config },
				cpp = { default_c_config },
				cuda = { default_c_config },
				python = {
					{
						type = 'debugpy',
						request = 'launch',
						name = 'Launch file',
						program = '${file}',
						pythonPath = function()
							if vim.fn.isdirectory('./.venv') == 1 then
								return './.venv/bin/python'
							else
								return '/usr/bin/python'
							end
						end
					}
				}
			}

			local open_callback = function() require('dapui').open(); require('nvim-dap-virtual-text').enable() end
			dap.listeners.before.attach.dapui_config = open_callback
			dap.listeners.before.launch.dapui_config = open_callback

			--- NOTE Temporary function to jump to next/previous breakpoint
			--- It uses an unstable API and therefore can break at any point
			--- See : https://github.com/mfussenegger/nvim-dap/issues/792
			--- Function credits to @chrisgrieser
			---@param dir 'next'|'prev'
			local function gotoBreakpoint(dir)
				local breakpoints = require('dap.breakpoints').get()
				if #breakpoints == 0 then
					vim.notify('No breakpoints set', vim.log.levels.WARN)
					return
				end
				local points = {}
				for bufnr, buffer in pairs(breakpoints) do
					for _, point in ipairs(buffer) do
						table.insert(points, { bufnr = bufnr, line = point.line })
					end
				end

				local current = {
					bufnr = vim.api.nvim_get_current_buf(),
					line = vim.api.nvim_win_get_cursor(0)[1]
				}

				local nextPoint
				for i = 1, #points do
					local isAtBreakpointI = points[i].bufnr == current.bufnr and points[i].line == current.line
					if isAtBreakpointI then
						local nextIdx = dir == 'next' and i + 1 or i - 1
						if nextIdx > #points then nextIdx = 1 end
						if nextIdx == 0 then nextIdx = #points end
						nextPoint = points[nextIdx]
						break
					end
				end
				if not nextPoint then nextPoint = points[1] end

				vim.cmd(('buffer +%s %s'):format(nextPoint.line, nextPoint.bufnr))
			end
			nmap(']b', function() gotoBreakpoint('next') end, 'Go to the next breakpoint')
			nmap('[b', function() gotoBreakpoint('prev') end, 'Go to the previous breakpoint')
		end,
		keys = {
			{ '<F9>',	'<cmd>DapToggleBreakpoint<CR>',		       desc = 'Debug toggle Breakpoint' },
			{ '<leader>db', '<cmd>DapToggleBreakpoint<CR>',		       desc = 'Debug toggle Breakpoint' },
			{ '<leader>dB', function()
					local cond = vim.fn.input('Condition: ')
					if #cond > 0 then
						require('dap').toggle_breakpoint(cond)
					end
				end,						       desc = 'Debug toggle conditional breakpoint' },
			{ '<F5>',	 '<cmd>DapContinue<CR>',		       desc = 'Debug Continue' },
			{ '<leader>dc', '<cmd>DapContinue<CR>',			       desc = 'Debug Continue' },
			{ '<leader>dC', function() require('dap').run_to_cursor() end, desc = 'Debug run to Cursor' },
			{ '<F10>',	'<cmd>DapStepOver<CR>',			       desc = 'Debug Step Next' },
			{ '<leader>dn', '<cmd>DapStepOver<CR>',			       desc = 'Debug Step Next' },
			{ '<F11>',	'<cmd>DapStepInto<CR>',			       desc = 'Debug Step Into' },
			{ '<leader>di', '<cmd>DapStepInto<CR>',			       desc = 'Debug Step Into' },
			{ '<F12>',	'<cmd>DapStepOut<CR>',			       desc = 'Debug Step Out' },
			{ '<leader>do', '<cmd>DapStepOut<CR>',			       desc = 'Debug Step Out' },
			{ '<leader>dt', '<cmd>DapTerminate<CR>',		       desc = 'Debug Terminate' },
			{ '<leader>dl', '<cmd>DapToggleRepl<CR>',		       desc = 'Debug up in the Stacktrace' },
			{ '<leader>dk', function() require('dap').up() end,	       desc = 'Debug up in the Stacktrace' },
			{ '<leader>dj', function() require('dap').down() end,	       desc = 'Debug down in the Stacktrace' },
			{ '<leader>dp', function() require('dap').pause() end,	       desc = 'Debug Pause' },
			{ '<leader>dr', function() require('dap').restart() end,       desc = 'Debug Restart' },
			{ '<leader>du', function() require('dapui').toggle();
				require('nvim-dap-virtual-text').toggle() end,	       desc = 'Debug toggle UI' }
		},
		cmd = { 'DapInstall', 'DapUninstall' },
		dependencies = {
			-- Debugging purposes
			{ 'mfussenegger/nvim-dap',
				cmd = {
					'DapContinue', 'DapLoadLaunchJSON', 'DapRestartFrame', 'DapSetLogLevel', 'DapShowLog',
					'DapStepInto', 'DapStepOut', 'DapStepOver', 'DapTerminate', 'DapToggleBreakpoint', 'DapToggleRepl'
				}
			},
			-- Tool to install LSPs, DAPs, linters and formatters
			'williamboman/mason.nvim',
			-- A UI for nvim-dap
			{ 'rcarriga/nvim-dap-ui', config = true },
			-- Adds virtual text support to nvim-dap. nvim-treesitter is used to find variable definitions
			{ 'theHamsta/nvim-dap-virtual-text',
				config = true,
				cmd = {
					'DapVirtualTextDisable', 'DapVirtualTextEnable',
					'DapVirtualTextForceRefresh', 'DapVirtualTextToggle'
				}
			},
			-- A library for asynchronous IO (for nvim-dap-ui)
			'nvim-neotest/nvim-nio'
		}
	},
	-- Autocompletion
	{ 'hrsh7th/nvim-cmp',
		event = 'InsertEnter',
		config = function()
			local cmp = require('cmp')
			require('luasnip.loaders.from_vscode').lazy_load()
			local luasnip = require('luasnip')

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end
				},
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
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<S-Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { 'i', 's' })
				}),
				sources = cmp.config.sources({
					-- LSP completion
					{ name = 'nvim_lsp' },
					-- Snippets
					{ name = 'luasnip' },
					-- Only for neovim settings
					{ name = 'lazydev', group_index = 0 },
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
			-- nvim-cmp source for neovim builtin LSP client
			'hrsh7th/cmp-nvim-lsp',
			-- nvim-cmp source for buffer words
			'hrsh7th/cmp-buffer',
			-- nvim-cmp source for vim's cmdline
			'hrsh7th/cmp-cmdline',
			-- Snippet Engine for Neovim written in Lua
			'L3MON4D3/LuaSnip',
			-- luasnip completion source for nvim-cmp
			'saadparwaiz1/cmp_luasnip'
		}
	},
	-- Allow use of background jobs
	{ 'tpope/vim-dispatch',
		keys = {
			{ '<localleader>tp', '<cmd>Dispatch! make preview<CR>',	 ft = { 'plaintex', 'tex', 'typst' }, desc = 'Preview LaTeX/typst document' },
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
			-- NOTE: Removes warning about not properly marked as optional fields
			---@diagnostic disable-next-line: missing-fields
			require('nvim-treesitter.configs').setup({
				-- Add languages to be installed here that you want installed for treesitter
				ensure_installed = {
					'bash', 'c', 'cpp', 'cuda', 'diff', 'haskell', 'html', 'javascript',
					'jsdoc', 'json', 'jsonc', 'lua', 'luadoc', 'luap', 'markdown_inline',
					'python', 'query', 'regex', 'toml', 'tsx', 'typescript', 'vim',
					'vimdoc', 'xml', 'yaml', 'typst',
					-- Requires tree-sitter-cli
					'latex'
				},
				highlight = { enable = true },
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
	-- Arduino commands
	{ 'stevearc/vim-arduino',
		keys = {
			{ '<leader>aa', '<cmd>ArduinoAttach<CR>',	    desc = 'Arduino: Attach board' },
			{ '<leader>av', '<cmd>ArduinoVerify<CR>',	    desc = 'Arduino: Verify sketch' },
			{ '<leader>au', '<cmd>ArduinoUpload<CR>',	    desc = 'Arduino: Upload sketch' },
			{ '<leader>ad', '<cmd>ArduinoUploadAndSerial<CR>',  desc = 'Arduino: Upload and serial' },
			{ '<leader>ab', '<cmd>ArduinoChooseBoard<CR>',	    desc = 'Arduino: Choose board' },
			{ '<leader>ap', '<cmd>ArduinoChooseProgrammer<CR>', desc = 'Arduino: Choose programmer' },
			{ '<leader>aP', '<cmd>ArduinoChoosePort<CR>',	    desc = 'Arduino: Choose port' },
			{ '<leader>as', '<cmd>ArduinoSerial<CR>',	    desc = 'Arduino: Serial' },
			{ '<leader>ai', '<cmd>ArduinoInfo<CR>',		    desc = 'Arduino: Info' }
		},
		cmd = {
			'ArduinoAttach', 'ArduinoVerify', 'ArduinoUpload', 'ArduinoUploadAndSerial',
			'ArduinoChooseBoard', 'ArduinoChooseProgrammer', 'ArduinoSerial', 'ArduinoChoosePort',
			'ArduinoInfo'
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
					{	'<leader>a',	group = 'Arduino' },
					{	'<leader>h',	group = 'Git' },
					{	'<leader>d',	group = 'Debugger' },
					{	'<leader>s',	group = 'Search' },
					{	'<leader>c',	group = 'Color picker' },
					{	'<leader>W',	group = 'Workspace' },
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
			show_buffer_close_icons = false,
			diagnostics = 'nvim_lsp',
			diagnostics_indicator = function(count) return '(' .. count .. ')' end
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
	-- Tool to install LSPs, DAPs, linters and formatters
	{ 'williamboman/mason.nvim',
		config = true,
		keys = { { '<leader>mo', function() if package.loaded['telescope'] == nil then require('telescope') end vim.cmd('Mason') end,
		desc = 'Open Mason manager' } },
		cmd = { 'Mason', 'MasonUpdate', 'MasonInstall', 'MasonUninstall', 'MasonUninstallAll', 'MasonLog' }
	},
	-- Easily update all Mason packages with one command
	{ 'RubixDev/mason-update-all',
		config = true,
		cmd = 'MasonUpdateAll',
		dependencies = {
			-- Tool to install LSPs, DAPs, linters and formatters
			'williamboman/mason.nvim'
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
	--Setup additional LSPs, linters and formatters
	{ 'jay-babu/mason-null-ls.nvim',
		event = 'VeryLazy',
		config = function()
			-- none-ls is a drop-in replacement for null-ls. Therefore it uses a mix of the old and new names
			local none_ls = require('null-ls')

			-- See available configs at : https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md
			-- And even additional configs at : https://github.com/nvimtools/none-ls-extras.nvim/
			local sources = {
				autopep8 = {
					require('none-ls.formatting.autopep8').with({
						extra_args = {
							'--max-line-length=150',
							'--ignore=E101,E11,E111,E121,E127,E128,E129,E301,E302,E402,E704,E265,E251,E305,E731,E122,E123,W191'
						}
					})
				},
				flake8 = {
					require('none-ls.diagnostics.flake8').with({
						extra_args = {
							'--max-line-length=150',
							'--ignore=W191,E302,E704,E101,E128,E265,E251,E301,E305,E731'
						}
					})
				},
				markdownlint = {
					none_ls.builtins.formatting.markdownlint,
					none_ls.builtins.diagnostics.markdownlint.with({
						extra_args = {
							'--disable line_length hard_tab'
						}
					})
				},
				prettier = {
					none_ls.builtins.formatting.prettier.with({
						extra_args = {
							'--print-width 150',
							'--tab-width 8',
							'--use-tabs'
						}
					})
				},
				hadolint = { none_ls.builtins.diagnostics.hadolint },
				shellcheck = {
					require('none-ls-shellcheck.diagnostics'),
					require('none-ls-shellcheck.code_actions')
				},
				checkmake = { none_ls.builtins.diagnostics.checkmake }
			}

			require('mason-null-ls').setup({
				ensure_installed = format_ensure_install(sources),
				automatic_installation = false
			})

			none_ls.setup({
				sources = reduce(sources, function(acc, _, source)
					for key_name, inner_source in pairs(source) do
						if key_name ~= '__skip_download' and key_name ~= '__package_name' then
							table.insert(acc, inner_source)
						end
					end
				end)
			})
		end,
		keys = { { '<leader>gf', vim.lsp.buf.format, desc = 'Format the document' } },
		cmd = { 'NullLsInstall', 'NoneLsInstall', 'NullLsUninstall', 'NoneLsUninstall' },
		dependencies = {
			-- Add additional LSP, linters and formatters not provided by williamboman/mason-lspconfig
			{ 'nvimtools/none-ls.nvim', cmd = { 'NullLsLog', 'NullLsInfo' } },
			-- Adding extra sources not included in none-ls
			'nvimtools/none-ls-extras.nvim',
			-- Shellcheck diagnostics and code-actions sources for none-ls.nvim
			'gbprod/none-ls-shellcheck.nvim',
			-- Lua library functions
			'nvim-lua/plenary.nvim'
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
			exclude = {
				filetypes = {
					'help', 'neo-tree',
					'lazy', 'mason', 'notify'
				}
			},
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
	-- Neovim support for the Lean theorem prover
	{ 'Julian/lean.nvim',
		ft = { 'lean' },
		opts = { infoview = { autoopen = false } },
		dependencies = {
			-- LSP Configuration & Plugins
			'neovim/nvim-lspconfig',
			-- Lua library functions
			'nvim-lua/plenary.nvim'
		},
		keys = { { '<localleader>tp', '<cmd>LeanInfoviewToggle<CR>', ft = 'lean', desc = "Toggle lean's info view" } },
		cmd = {
			'LeanAbbreviationsReverseLookup', 'LeanGoal', 'LeanGotoInfoview', 'LeanInfoviewAddPin', 'LeanInfoviewClearDiffPin',
			'LeanInfoviewClearPins', 'LeanInfoviewDisableWidgets', 'LeanInfoviewEnableWidgets', 'LeanInfoviewPinTogglePause',
			'LeanInfoviewSetDiffPin', 'LeanInfoviewToggle', 'LeanInfoviewToggleAutoDiffPin', 'LeanInfoviewToggleNoClearAutoDiffPin',
			'LeanInfoviewViewOptions', 'LeanLineDiagnostics', 'LeanPlainDiagnostics', 'LeanPlainGoal', 'LeanPlainTermGoal',
			'LeanRefreshFileDependencies', 'LeanRestartFile', 'LeanSorryFill', 'LeanTermGoal'
		}
	},
	-- Provides external LTeX file handling (off-spec lsp) and other functions.
	{ 'barreiroleo/ltex_extra.nvim',
		ft = { 'markdown', 'plaintex', 'tex' },
		config = function()
			local function setup_ltex(lang)
				local capabilities = vim.lsp.protocol.make_client_capabilities()
				capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

				require('lspconfig')['ltex'].setup({
					capabilities = capabilities,
					on_attach = function(_, _)
						require('ltex_extra').setup({
							load_langs = { 'fr', 'en-GB' },
							init_check = true,
							path = vim.fn.stdpath 'config' .. '/spell/dictionaries',
						})
					end,
					settings = {
						ltex = {
							configurationTarget = {
								dictionary = 'user',
								disabledRules = 'workspaceFolderExternalFile',
								hiddenFalsePositives = 'workspaceFolderExternalFile'
							},
							language = lang
						}
					}
				})
			end

			setup_ltex('fr')

			local ltex_languages = {
				'auto', 'ar', 'ast-ES', 'be-BY', 'br-FR', 'ca-ES', 'ca-ES-valencia',
				'da-DK', 'de', 'de-AT', 'de-CH', 'de-DE', 'de-DE-x-simple-language',
				'el-GR', 'en', 'en-AU', 'en-CA', 'en-GB', 'en-NZ', 'en-US', 'en-ZA',
				'eo', 'es', 'es-AR', 'fa', 'fr', 'ga-IE', 'gl-ES', 'it', 'ja-JP',
				'km-KH', 'nl', 'nl-BE', 'pl-PL', 'pt', 'pt-AO', 'pt-BR', 'pt-MZ',
				'pt-PT', 'ro-RO', 'ru-RU', 'sk-SK', 'sl-SI', 'sv', 'ta-IN', 'tl-PH',
				'uk-UA', 'zh-CN'
			}

			vim.api.nvim_create_user_command('LtexSwitchLang', function(args)
				local splited_args = vim.split(args.args, ' ', { trimemtpy = true })
				local ltex_clients = vim.lsp.get_clients({ bufnr = 0, name = 'ltex' })
				for _, ltex_client in ipairs(ltex_clients) do
					vim.lsp.stop_client(ltex_client.id, false)
				end
				setup_ltex(splited_args[1])
			end, {
				nargs = 1,
				complete = function (ArgLead, _, _)
					return vim.tbl_filter(function(el) return el:find(ArgLead, 1, true) end, ltex_languages)
				end
			})
		end,
		dependencies = {
			-- LSP Configuration & Plugins
			'neovim/nvim-lspconfig'
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
					{ pane = 2, title = "The honest philosopher seeks only the truth,\neven if it bears no comfort.", align = 'center', padding = 1 },
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
			{ '<leader>on', function() require('snacks').terminal('lazynpm') end,	 desc = 'Open lazynpm' },
			{ '<leader>ob', function() require('snacks').terminal('btop') end,	 desc = 'Open btop' },
			{ '<leader>ot', function() require('snacks').terminal() end,		 desc = 'Open terminal' }
		}
	}
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
vim.o.mouse					= 'a'										-- Enable mouse mode (selection, scrolling etc.)
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
nmap('<leader>p', '"+p',													   'Paste the system clipboard after the cursor')
nmap('<leader>P', '"+P',													   'Paste the system clipboard before the cursor')
vmap('<leader>y', '"+y',													   'Yank into the system clipboard')
nmap('<leader>y', '"+Y',													   'Yank the entire buffer into the system clipboard')
nmap('<leader>fx', '<cmd>!chmod +x %<CR>',											   'Make the current file executable')
nmap('<leader>fX', '<cmd>!chmod -x %<CR>',											   'Make the current file non executable')
create_cmd('Settings', 'e $MYVIMRC', 												   'Edit Neovim config file')
create_cmd('EspansoEdit', 'e ' .. vim.fn.stdpath 'config' .. '/../espanso/match/base.yml',					   'Edit Espanso config file')
