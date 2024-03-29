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
local function imap(key, action, desc, buffer) map('i', key, action, desc, buffer) end
local function vmap(key, action, desc, buffer) map('v', key, action, desc, buffer) end
local function Autocmd(events, pattern, callback)
	vim.api.nvim_create_autocmd(events, { pattern = pattern, callback = callback })
end
local function filter(sequence, predicate)
	local new_list = {}
	for k, v in pairs(sequence) do
		if predicate(k, v) then
			new_list[k] = v
		end
	end
	return new_list
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Plugin enabler
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({ 'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key to space
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('lazy').setup({
	-- Install the vscode's codedark theme
	{ 'tomasiser/vim-code-dark',
		priority = 1000,
		config = function()
			vim.cmd.colorscheme('codedark')

			-- Fix the git colours palette
			vim.api.nvim_set_hl(0, 'GitSignsAdd',	 { ctermfg = 10, fg = '#009900' })
			vim.api.nvim_set_hl(0, 'GitSignsChange', { ctermfg = 14, fg = '#bbbb00' })
			vim.api.nvim_set_hl(0, 'GitSignsDelete', { ctermfg = 12, fg = '#ff2222' })
		end
	},
	-- Add a fancy bottom bar with details
	{ 'nvim-lualine/lualine.nvim',
		event = 'VeryLazy',
		opts = {
			options = {
				theme = 'codedark',
				disabled_filetypes = { 'NvimTree' },
				ignore_focus = {
					'dapui_watches', 'dapui_breakpoints',
					'dapui_scopes', 'dapui_console',
					'dapui_stacks', 'dap-repl'
				}
			}
		},
		dependencies = 'nvim-tree/nvim-web-devicons'
	},
	-- Add the left column indicating git line status and preview window
	{ 'lewis6991/gitsigns.nvim',
		event = 'VeryLazy',
		config = function()
			local gs = require('gitsigns')
			gs.setup({})
			require('scrollbar.handlers.gitsigns').setup({})
			nmap(		  '<leader>hp', gs.preview_hunk,		'[H]unk [P]review')
			map({ 'n', 'v' }, '<leader>hR', gs.reset_hunk,			'[H]unk [R]eset')
			map({ 'n', 'v' }, '<leader>hs', gs.stage_hunk,			'[H]unk [S]tage')
			nmap(		  '<leader>hu', gs.undo_stage_hunk,		'[H]unk [U]ndo')
			nmap(		  '<leader>hd', gs.diffthis,			'[H]unk [D]iff this')
			nmap(		  '<leader>hb', gs.toggle_current_line_blame,	'[H]unk toggle line [B]lame')
			nmap(		  '[h', function() gs.prev_hunk(); if vim.o.diff then return end gs.preview_hunk_inline() end, 'Previous [H]unk')
			nmap(		  ']h', function() gs.next_hunk(); if vim.o.diff then return end gs.preview_hunk_inline() end, 'Next [H]unk')
		end,
		dependencies = { 'nvim-lua/plenary.nvim', 'petertriho/nvim-scrollbar' }
	},
	-- Colourize RGB codes to it designated colour and add a colour picker
	{ 'uga-rosa/ccc.nvim',
		event = 'VeryLazy',
		cmd = { 'CccPick', 'CccConvert', 'CccHighlighterEnable', 'CccHighlighterDisable', 'CccHighlighterToggle' },
		keys = {
			{'<leader>cp', '<cmd>CccPick<CR>',			desc = 'open [C]olour [P]icker'},
			{'<leader>cc', '<cmd>CccConvert<CR>',			desc = '[C]olour [C]onvert'},
			{'<leader>ct', '<cmd>CccHighlighterToggle<CR>',		desc = '[C]olour highlight [T]oggle'},
			{'<leader>ce', '<cmd>CccHighlighterEnable<CR>',		desc = '[C]olour highlight [E]nable'},
			{'<leader>cd', '<cmd>CccHighlighterDisable<CR>',	desc = '[C]olour highlight [D]isable'}
		},
		opts = { highlighter = { auto_enable = true } }
	},
	-- Quickly surround word with given symbol
	{ 'kylechui/nvim-surround', event = 'VeryLazy', config = true },
	-- Add fuzzy finder to files, command and more
	{ 'nvim-telescope/telescope.nvim',
		event = 'VeryLazy',
		config = function()
			local telescope = require('telescope')
			telescope.setup({ extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown({}) } } })
			local tbi = require('telescope.builtin')
			nmap('<leader>sf', tbi.find_files,	'[S]earch [F]iles')
			nmap('<leader>sh', tbi.help_tags,	'[S]earch [H]elp')
			nmap('<leader>sw', tbi.grep_string,	'[S]earch current [W]ord')
			nmap('<leader>sg', tbi.live_grep,	'[S]earch by [G]rep')
			nmap('<leader>sd', tbi.diagnostics,	'[S]earch [D]iagnostics')
			nmap('<leader>sk', tbi.keymaps,		'[S]earch [K]eymaps')
			nmap('<leader>sc', tbi.commands,	'[S]earch [c]ommands')
			nmap('<leader>sb', tbi.buffers,		'[S]earch [B]uffers')
			nmap('<leader>sm', tbi.marks,		'[S]earch [M]arks')
			nmap('<leader>sr', tbi.registers,	'[S]earch [R]egisters')
			nmap('<leader>ss', tbi.resume,		'[S]earch re[S]ume')
			telescope.load_extension('ui-select')

			nmap('<leader>st', '<cmd>TodoTelescope<CR>', '[S]earch [T]odo elements')
		end,
		dependencies = {
			-- Bind vim.ui.select to telescope
			'nvim-telescope/telescope-ui-select.nvim',
			-- Lua library functions
			'nvim-lua/plenary.nvim',
			-- Provides nerd fonts icons
			'nvim-tree/nvim-web-devicons',
			-- Highlight todo, notes, etc in comments
			'folke/todo-comments.nvim'
		}
	},
	-- Automatic pairs of ( [ { insertion
	{ 'windwp/nvim-autopairs', config = true },
	-- Add a fancy file explorer
	{ 'nvim-tree/nvim-tree.lua',
		event = 'VeryLazy',
		keys = {
			{ '<C-n>', '<cmd>NvimTreeToggle<CR>',	desc = 'Open [N]erd tree explorer' }
		},
		opts = {
			filters = {
				custom = {
					'.git',
					'node_modules',
					'venv',
					'package-lock.json'
				}
			},
			sync_root_with_cwd = true,
			actions = { open_file = { quit_on_open = true } }
		},
		dependencies = 'nvim-tree/nvim-web-devicons'
	},
	-- add the vmap gl<SYMBOL> to vertical align to the given symbol
	{ 'tommcdo/vim-lion',
		event = 'VeryLazy',
		config = function()
			vim.g.lion_squeeze_spaces = 1		-- Squeeze extra spaces when doing a vertical alignment
		end
	},
	-- Automatic white spaces trimming
	{ 'ntpeters/vim-better-whitespace',
		event = 'VeryLazy',
		config = function()
			vim.g.better_whitespace_enabled = 1	-- Enable the plugin
			vim.g.strip_whitespace_on_save  = 1	-- Remove trailing white spaces on save
			vim.g.strip_whitespace_confirm  = 0	-- Disable the confirmation message on stripping white spaces
		end
	},
	-- CSV file handling
	{ 'chrisbra/csv.vim',
		event = 'VeryLazy',
		config = function()
			vim.b.csv_arrange_align = 'lc.'		-- Left align when using ArrangeColumn in a csv file
		end
	},
	-- LSP Configuration & Plugins
	{ 'neovim/nvim-lspconfig',
		event = 'BufRead',
		config = function()
			require('neodev').setup({})		-- Setup neovim lua configuration
			require('fidget').setup({		-- Turn on lsp status information
				integration = { ['nvim-tree'] = { enable = true } }
			})

			nmap('<leader>rn', vim.lsp.buf.rename,						'LSP: [R]e[n]ame')
			nmap('gd',	   vim.lsp.buf.definition,					'LSP: [G]oto [D]efinition')
			nmap('gI',	   vim.lsp.buf.implementation,					'LSP: [G]oto [I]mplementation')
			nmap('<leader>D',  vim.lsp.buf.type_definition,					'LSP: Type [D]efinition')
			nmap('K',	   vim.lsp.buf.hover,						'LSP: Hover Documentation')
			--nmap('<M-k>',	   vim.lsp.buf.signature_help,					'LSP: Signature Documentation')
			nmap('gD',	   vim.lsp.buf.declaration,					'LSP: [G]oto [D]eclaration')
			nmap('<leader>e',  vim.diagnostic.open_float,					'LSP: Show diagnostic [E]rror message')

			nmap('gr',	   require('telescope.builtin').lsp_references,			'LSP: [G]oto [R]eferences')
			--nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols,		'LSP: [D]ocument [S]ymbols')
			nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols,	'LSP: [W]orkspace [S]ymbols')

			nmap('<leader>ca', vim.lsp.buf.code_action,					'LSP: [C]ode [A]ction')
			nmap('[d',	   vim.diagnostic.goto_prev,					'LSP: Jump to previous [D]iagnostics')
			nmap(']d',	   vim.diagnostic.goto_next,					'LSP: Jump to next [D]iagnostics')
			nmap('<leader>q',  vim.diagnostic.setloclist,					'LSP: Open diagnostic [Q]uickfix')

			local lspconfig = require('lspconfig')
			local root_pattern = lspconfig.util.root_pattern
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

			-- Enable the following language servers with overriding configuration
			-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
			local servers = {
				lua_ls = {
					Lua = {
						runtime = { version = 'LuaJIT' },
						workspace = {
							checkThirdParty = false,
							library = { '${3rd}/luv/library', unpack(vim.api.nvim_get_runtime_file('', true)) }
						},
						completion = { callSnippet = 'Replace' },
						telemetry = { enable = false }
					}
				},
				clangd = {
					__skip = true,
					CompileFlags = {
						add = { '-I/opt/cuda/targets/x86_64-linux/include' }
					}
				},
				tsserver = {},
				hls = {
					__skip = true,
					cmd = { 'haskell-language-server-wrapper', '--lsp' },
					filetypes = { 'haskell', 'lhaskell', 'cabal' },
					root_dir = root_pattern('*.cabal', 'stack.yaml', 'cabal.project', 'package.yaml', 'hie.yaml')
				},
				cmake = {},
				bashls = {},
				pyright = {}
			}

			local mason_lspconfig = require('mason-lspconfig')
			mason_lspconfig.setup({
				ensure_installed = vim.tbl_keys(filter(servers, function(_, server) return server.__skip ~= true end))
			})

			for name, opts in pairs(servers) do
				lspconfig[name].setup({
					capabilities = capabilities,
					on_attach = on_attach,
					settings = opts
				})
			end
		end,
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			'williamboman/mason.nvim', 'williamboman/mason-lspconfig.nvim',
			-- Useful status updates for LSP
			'j-hui/fidget.nvim',
			-- Additional lua configurations, make nvim stuff amazing
			'folke/neodev.nvim',
			-- Auto completion functionalities
			'hrsh7th/cmp-nvim-lsp'
		}
	},
	-- Debugging purposes
	{ 'mfussenegger/nvim-dap',
		event = 'VeryLazy',
		config = function()
			local dap = require('dap')


			dap.adapters = {
				cppdbg = {
					id = 'cppdbg',
					type = 'executable',
					command = 'OpenDebugAD7'
				},
				debugpy = {
					id = 'debugpy',
					type = 'executable',
					command = 'debugpy-adapter'
				}
			}

			dap.configurations = {
				cpp = {
					{
						name = 'Launch file',
						type = 'cppdbg',
						request = 'launch',
						program = function()
							return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
						end,
						cwd = '${workspaceFolder}',
						stopAtEntry = true
					}
				},
				cuda = {
					{
						name = 'Launch file',
						type = 'cppdbg',
						request = 'launch',
						program = function()
							return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
						end,
						cwd = '${workspaceFolder}',
						stopAtEntry = true
					}
				},
				python = {
					{
						type = 'debugpy',
						request = 'launch',
						name = 'Launch file',
						program = '${file}',
						pythonPath = function()
							return '/usr/bin/python'
						end
					},
					{
						type = 'debugpy',
						request = 'launch',
						name = 'Launch file (venv)',
						program = '${file}',
						pythonPath = function()
							return '${workspaceFolder}/venv/bin/python'
						end
					}
				}
			}

			nmap('<leader>db',		 dap.toggle_breakpoint,					'[D]ebug toggle [B]reakpoint]')
			nmap({ '<leader>dc', '<F5>' },	 dap.continue,						'[D]ebug [C]ontinue')
			nmap({ '<leader>dC', '<F7>' },	 dap.run_to_cursor,					'[D]ebug run to [C]ursor')
			nmap({ '<leader>do', '<F10>' },	 dap.step_over,						'[D]ebug Step [O]ver')
			nmap({ '<leader>di', '<F11>' },	 dap.step_into,						'[D]ebug Step [I]nto')
			nmap({ '<leader>dO', '<F12>' },	 dap.step_out,						'[D]ebug Step [O]ut')
			nmap({ '<leader>dt', '<S-F5>' }, dap.terminate,						'[D]ebug [T]erminate')
			nmap('<leader>ds',		 dap.up,						'[D]ebug up in the [S]tacktrace')
			nmap('<leader>dS',		 dap.down,						'[D]ebug down in the [S]tacktrace')
			nmap('<leader>dp',		 dap.pause,						'[D]ebug [P]ause')
			nmap({ '<leader>dr', '<C-F5>' }, function() dap.terminate(); dap.continue(); end,	'[D]ebug [R]estart')
		end
	},
	{ 'rcarriga/nvim-dap-ui',
		event = 'VeryLazy',
		config = function()
			local dap = require('dap')
			local dapui = require('dapui')
			dapui.setup()

			dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open({}) end
			dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close({}) end
			dap.listeners.before.event_exited['dapui_config'] = function() dapui.close({}) end
			vim.fn.sign_define('DapBreakpoint',		{ text = '', texthl = 'DapUIBreakpointsInfo' })
			vim.fn.sign_define('DapBreakpointCondition',	{ text = '', texthl = 'DapUIBreakpointsInfo' })
			vim.fn.sign_define('DapBreakpointRejected',	{ text = '', texthl = 'DapUIBreakpointsInfo' })
			vim.fn.sign_define('DapLogPoint',		{ text = '', texthl = 'DapUIBreakpointsInfo' })
			vim.fn.sign_define('DapStopped',		{ text = '', texthl = 'DapUIStopped' })

			nmap('<leader>du', dapui.toggle, '[D]ebug toggle [U]I')
		end,
		dependencies = {
			'mfussenegger/nvim-dap',
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
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' }
				}, {
					{ name = 'buffer' }
				})
			})
		end,
		dependencies = {
			'hrsh7th/cmp-nvim-lsp',
			'L3MON4D3/LuaSnip',
			'saadparwaiz1/cmp_luasnip'
		}
	},
	-- Allow use of background jobs
	{ 'tpope/vim-dispatch',
		keys = {
			{'<leader>tp', '<cmd>Dispatch! make preview<CR>', desc = 'La[T]eX [P]review document'},
			-- TUI programs
			{'<leader>$g', '<cmd>Start lazygit<CR>',    desc = 'Open Lazy[G]it'},
			{'<leader>$d', '<cmd>Start lazydocker<CR>', desc = 'Open Lazy[D]ocker'}
		},
		config = function()
			Autocmd('BufWritePost', '*.tex', function() vim.cmd('Spawn! make') end)		-- Auto compile LaTeX document on save
		end,
		cmd = { 'Dispatch', 'Make', 'Focus', 'Start', 'Spawn' }
	},
	-- Highlight, edit, and navigate code
	{ 'nvim-treesitter/nvim-treesitter',
		event = 'VeryLazy',
		config = function()
			require('nvim-treesitter.configs').setup({
				-- Add languages to be installed here that you want installed for treesitter
				ensure_installed = { 'c', 'cpp', 'cuda', 'lua', 'python', 'haskell', 'javascript', 'typescript' },
				highlight = { enable = true },
				indent = { enable = false }
			})
		end,
		build = '<cmd>TSUpdate'
	},
	-- Colourize multiple inner level to ( [ {
	{ 'HiPhish/rainbow-delimiters.nvim', event = 'VeryLazy', dependencies = 'nvim-treesitter/nvim-treesitter' },
	-- Arduino commands
	{ 'stevearc/vim-arduino',
		keys = {
			{'<leader>aa', '<cmd>ArduinoAttach<CR>',		desc = '[A]rduino [A]ttach'},
			{'<leader>av', '<cmd>ArduinoVerify<CR>',		desc = '[A]rduino [V]erify'},
			{'<leader>au', '<cmd>ArduinoUpload<CR>',		desc = '[A]rduino [U]pload'},
			{'<leader>ad', '<cmd>ArduinoUploadAndSerial<CR>',	desc = '[A]rduino upload an[D] serial'},
			{'<leader>ab', '<cmd>ArduinoChooseBoard<CR>',		desc = '[A]rduino choose [B]oard'},
			{'<leader>ap', '<cmd>ArduinoChooseProgrammer<CR>',	desc = '[A]rduino choose [P]rogrammer'},
			{'<leader>aP', '<cmd>ArduinoChoosePort<CR>',		desc = '[A]rduino choose [P]ort'},
			{'<leader>as', '<cmd>ArduinoSerial<CR>',		desc = '[A]rduino [S]erial'},
			{'<leader>ai', '<cmd>ArduinoInfo<CR>',			desc = '[A]rduino [I]nfo'}
		},
		cmd = {
			'ArduinoAttach', 'ArduinoVerify', 'ArduinoUpload', 'ArduinoUploadAndSerial',
			'ArduinoChooseBoard', 'ArduinoChooseProgrammer', 'ArduinoSerial', 'ArduinoChoosePort',
			'ArduinoInfo'
		}
	},
	-- Show a togglable undotree
	{ 'mbbill/undotree', keys = { { '<leader>ut', '<Cmd>UndotreeToggle<CR>', desc = 'Open [U]ndo [T]ree' } } },
	-- Display a popup with possible key bindings of the command you started typing
	{ 'folke/which-key.nvim',
		event = 'VeryLazy',
		config = true,
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 200
		end
	},
	-- Stylize the bufferline
	{ 'akinsho/bufferline.nvim', event = 'VeryLazy', opts = { options = { mode = 'tabs' } }, dependencies = 'nvim-tree/nvim-web-devicons' },
	-- Tool to install LSPs, DAPs, linters and formatters
	{ 'williamboman/mason.nvim',
		config = true,
		cmd = { 'Mason', 'MasonUpdate' },
		keys = { { '<leader>mo', '<cmd>Mason<CR>', desc = '[M]ason [O]pen' } }
	},
	-- Easily update all Mason packages with one command
	{ 'RubixDev/mason-update-all', cmd = { 'MasonUpdateAll' }, config = true, dependencies = 'williamboman/mason.nvim' },
	-- Greeter for neovim
	{ 'goolord/alpha-nvim',
		event = 'VimEnter',
		cmd = { 'Alpha' },
		config = function()
			local startify = require('alpha.themes.startify')

			startify.section.header.opts.position = 'center'
			startify.section.header.val = {
				'                                                                     ',
				'       ████ ██████           █████      ██                     ',
				'      ███████████             █████                             ',
				'      █████████ ███████████████████ ███   ███████████   ',
				'     █████████  ███    █████████████ █████ ██████████████   ',
				'    █████████ ██████████ █████████ █████ █████ ████ █████   ',
				'  ███████████ ███    ███ █████████ █████ █████ ████ █████  ',
				' ██████  █████████████████████ ████ █████ █████ ████ ██████ '
			}

			require('alpha').setup(startify.config)
		end,
		dependencies = 'nvim-tree/nvim-web-devicons'
	},
	-- Add an extensible scrollbar
	{ 'petertriho/nvim-scrollbar',
		event = 'VeryLazy',
		opts = {
			show_in_active_only = true,
			handlers = {
				search = true, -- Binding for hlslens
				gitsigns = true
			}
		},
		dependencies = { 'lewis6991/gitsigns.nvim', 'kevinhwang91/nvim-hlslens' }
	},
	-- Helps getting better glance at matched information, seamlessly jump between matched instances.
	{ 'kevinhwang91/nvim-hlslens',
		event = 'VeryLazy',
		config = true,
		keys = {
			{ 'n', "<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>zz", 'Repeat the latest "/" or "?" [count] times forward' },
			{ 'N', "<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>zz", 'Repeat the latest "/" or "?" [count] times backward' },
			{ '*', "*<Cmd>lua require('hlslens').start()<CR>", "Search forward for the [count]'th occurrence of the whole word" },
			{ '#', "#<Cmd>lua require('hlslens').start()<CR>", "Search backward for the [count]'th occurrence of the whole word" },
			{ 'g*', "g*<Cmd>lua require('hlslens').start()<CR>", "Search forward for the [count]'th occurrence of the word" },
			{ 'g#', "g#<Cmd>lua require('hlslens').start()<CR>", "Search backward for the [count]'th occurrence of the word" }
		}
	},
	-- Make folding look modern
	{ 'kevinhwang91/nvim-ufo',
		event = 'VeryLazy',
		opts = { provider_selector = function() return { 'treesitter', 'indent' } end },
		dependencies = 'kevinhwang91/promise-async'
	},
	-- Add formatters and linters
	-- See available configs at : https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
	{ 'nvimtools/none-ls.nvim',
		event = 'BufRead',
		config = function()
			local null_ls = require('null-ls')
			local cspell = require('cspell')

			null_ls.setup({
				sources = {
					-- TODO Deprecated
					require('none-ls.formatting.autopep8').with({
						extra_args = {
							'--max-line-length=150',
							'--ignore=E101,E11,E111,E121,E127,E128,E129,E301,E302,E402,E704,E265,E251,E305,E731,E122,E123,W191'
						}
					}),
					-- TODO Deprecated
					require('none-ls.diagnostics.flake8').with({
						extra_args = {
							'--max-line-length=150',
							'--ignore=W191,E302,E704,E101,E128,E265,E251,E301,E305,E731'
						}
					}),
					cspell.diagnostics,
					cspell.code_actions,
					--null_ls.builtins.diagnostics.cspell.with({
						--language = 'en-GB,fr,de,it,es,ru',
						--enableDictionaries = { 'medical-terms', 'french', 'german' },
						--userWords = {
						--	'Artix', 'Bpedia', 'Codium', 'Corese', 'Elem', 'Fullscreen', 'Hadoop', 'Hasklug', 'INET', 'KGRAM', 'Keras', 'LUBM', 'MIAGE', 'PESTEL',
						--	'Polytech', 'RDFS', 'SPARQL', 'SPARQLGX', 'Tyrex', 'Underwaters', 'WGAN', 'Wimmics', 'alacritty', 'asarray', 'astype', 'autopep',
						--	'bluez', 'ccls', 'cdrom', 'clangd', 'classif', 'connman', 'connmanctl', 'cuda', 'darkside', 'dockeriser', 'dockerisé', 'dotfiles',
						--	'dtype', 'imgur', 'imshow', 'includegraphics', 'ipywidgets', 'isdir', 'jupyterlab', 'markdownlint', 'matplotlib', 'ndarray', 'neofetch',
						--	'neovim', 'njit', 'numba', 'numpy', 'objc', 'objcpp', 'pacman', 'pactl', 'padx', 'picom', 'polybar', 'pulseaudio', 'pulsemixer',
						--	'pyplot', 'qcow', 'saundersp', 'scikit', 'shellui', 'sklearn', 'tabspaces', 'texhash', 'tllocalmgr', 'tolist', 'torchsummary',
						--	'torchvision', 'tqdm', 'xclip', 'xinit', 'xorg', 'xset'
						--}
					--}),
					null_ls.builtins.formatting.markdownlint,
					null_ls.builtins.diagnostics.markdownlint.with({
						extra_args = {
							'--disable line_length hard_tab'
						}
					}),
					null_ls.builtins.formatting.prettier.with({
						extra_args = {
							'--print-width 150',
							'--tab-width 8',
							'--use-tabs'
						}
					})
				}
			})
		end,
		keys = {
			{ '<leader>gf', vim.lsp.buf.format, desc = 'Format the document' }
		},
		dependencies = {
			-- Lua library functions
			'nvim-lua/plenary.nvim',
			-- Adding extra sources not included in none-ls
			'nvimtools/none-ls-extras.nvim',
			-- Adding support for cspell diagnostics and code actions
			'davidmh/cspell.nvim'
		}
	},
	-- Bring automated annotation
	{ 'danymat/neogen',
		event = 'VeryLazy',
		config = function()
			local neogen = require('neogen')
			neogen.setup({})
			nmap('<leader>ng', neogen.generate)
			imap('<C-l>', neogen.jump_next)
			nmap('<C-l>', neogen.jump_next)
			imap('<C-h>', neogen.jump_prev)
			nmap('<C-h>', neogen.jump_prev)
		end,
		dependencies = 'nvim-treesitter/nvim-treesitter'
	},
	-- Hex editing done right
	{ 'RaafatTurki/hex.nvim',
		keys = {
			{ '<leader>x', "<cmd>lua require('hex').toggle()<CR>", 'Toggle between hex view and normal view' }
		}
	},
	-- Better navigation inside tmux
	{ 'alexghergh/nvim-tmux-navigation',
		event = 'VimEnter',
		config = function()
			local nvim_tmux_nav = require('nvim-tmux-navigation')
			nvim_tmux_nav.setup({ disable_when_zoomed = true })
			nmap('<C-b>h', nvim_tmux_nav.NvimTmuxNavigateLeft,	'Navigate to the left tmux pane if existent')
			nmap('<C-b>j', nvim_tmux_nav.NvimTmuxNavigateDown,	'Navigate to the down tmux pane if existent')
			nmap('<C-b>k', nvim_tmux_nav.NvimTmuxNavigateUp,	'Navigate to the up tmux pane if existent')
			nmap('<C-b>l', nvim_tmux_nav.NvimTmuxNavigateRight,	'Navigate to the right tmux pane if existent')
		end
	},
	-- Highlight todo, notes, etc in comments
	{ 'folke/todo-comments.nvim',
		event = 'VeryLazy',
		dependencies = 'nvim-lua/plenary.nvim',
		config = function()
			local todo = require('todo-comments')
			todo.setup({
				signs = false,
				highlight = { pattern = '.*<(KEYWORDS)\\s*[: ]' },
				search = { pattern = '\\b(KEYWORDS)[: ]' }
			})
			nmap(']t', todo.jump_next, 'Next todo comment')
			nmap('[t', todo.jump_prev, 'Previous todo comment')
		end
	}
})
local lazy = require('lazy')
nmap('<leader>lo', lazy.home,		'[L]azy [O]pen home')
nmap('<leader>lu', lazy.update,		'[L]azy [U]pdate')
nmap('<leader>ls', lazy.sync,		'[L]azy [S]ync')
nmap('<leader>lp', lazy.profile,	'[L]azy [P]rofile')

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- General settings configuration
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vim.o.mouse					= 'a'										-- Enable mouse mode (selection, scrolling etc.)
vim.o.termguicolors				= true										-- Enable 24-bit RGB colours in the terminal
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
nmap('<leader>p', '"+p',													   'Paste the system clipboard after the cursor')
nmap('<leader>P', '"+P',													   'Paste the system clipboard before the cursor')
vmap('<leader>y', '"+y',													   'Yank into the system clipboard')
nmap('<leader>y', '"+Y',													   'Yank the entire buffer into the system clipboard')
nmap('<leader>fx', '<cmd>!chmod +x %<CR>',											   'Make the current file executable')
nmap('<leader>fX', '<cmd>!chmod -x %<CR>',											   'Make the current file non executable')
vim.api.nvim_create_user_command('EditConfig', 'e $MYVIMRC', { desc =								   'Edit Neovim config file' })
vim.api.nvim_create_user_command('EspansoEdit', 'e ' .. vim.fn.stdpath 'config' .. '/../espanso/match/base.yml', { desc =	   'Edit Espanso config file' })
