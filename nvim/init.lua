--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Pre startup
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if package.loaded['impatient'] then
else
	for _, searcher in ipairs(package.searchers or package.loaders) do
		local loader = searcher('impatient')
		if type(loader) == 'function' then
			package.preload['impatient'] = loader
			require('impatient')
			break
		end
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global shortcuts/helper
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function map(mode, key, action, desc, buffer)
	if type(key) == 'table' then
		for _,e in ipairs(key) do
			map(mode, e, action, desc, buffer)
		end
	else
		vim.keymap.set(mode, key, action, { silent = true, buffer = buffer, desc = desc })
	end
end
function nmap(key, action, desc, buffer) map('n', key, action, desc, buffer) end
function vmap(key, action, desc, buffer) map('v', key, action, desc, buffer) end
function Autocmd(events, pattern, callback)
	vim.api.nvim_create_autocmd(events, { pattern = pattern, callback = callback })
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Plugin enabler
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key to space
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('lazy').setup({
	-- Faster nvim startup time (see Pre startup)
	'lewis6991/impatient.nvim',
	-- Install the vscode's codedark theme
	{ 'tomasiser/vim-code-dark',
		priority = 1000,
		config = function()
			vim.cmd.colorscheme('codedark')
		end
	},
	-- Add a fancy bottom bar with details
	{ 'nvim-lualine/lualine.nvim',
		opts = {
			options = {
				theme = 'codedark',
				disabled_filetypes = { 'NvimTree' },
				ignore_focus = {
					'dapui_watches', 'dapui_breakpoints',
					'dapui_scopes', 'dapui_console',
					'dapui_stacks', 'dap-repl'
				}
			},
			sections = {
				lualine_x = {
					{
						require('lazy.status').updates,
						cond = require('lazy.status').has_updates,
						color = { fg = '#ff9e64' }
					}
				}
			}
		},
		dependencies = 'kyazdani42/nvim-web-devicons'
	},
	-- Add the left column indicating git line status and preview window
	{ 'lewis6991/gitsigns.nvim',
		config = function()
			local gs = require('gitsigns')
			gs.setup({})
			nmap(		  '<leader>hp', gs.preview_hunk,		'[H]unk [P]review')
			map({ 'n', 'v' }, '<leader>hR', gs.reset_hunk,			'[H]unk [R]eset')
			map({ 'n', 'v' }, '<leader>hs', gs.stage_hunk,			'[H]unk [S]tage')
			nmap(		  '<leader>hu', gs.undo_stage_hunk,		'[H]unk [U]ndo')
			nmap(		  '<leader>hd', gs.diffthis,			'[H]unk [D]iff this')
			nmap(		  '<leader>hb', gs.toggle_current_line_blame,	'[H]unk toggle line [B]lame')
			nmap(		  '[h', function() gs.prev_hunk(); if vim.o.diff then return end gs.preview_hunk_inline() end, 'Previous [H]unk')
			nmap(		  ']h', function() gs.next_hunk(); if vim.o.diff then return end gs.preview_hunk_inline() end, 'Next [H]unk')

			-- Configure the git colours palette
			vim.api.nvim_set_hl(0, 'GitSignsAdd',	 { ctermfg = 10, fg = '#009900' })
			vim.api.nvim_set_hl(0, 'GitSignsChange', { ctermfg = 14, fg = '#bbbb00' })
			vim.api.nvim_set_hl(0, 'GitSignsDelete', { ctermfg = 12, fg = '#ff2222' })
		end,
		dependencies = 'nvim-lua/plenary.nvim'
	},
	-- Colourize RGB codes to it designated colour and add a colour picker
	{ 'uga-rosa/ccc.nvim',
		lazy = false,
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
	{ 'kylechui/nvim-surround', config = true },
	-- Add fuzzy finder to files, command and more
	{ 'nvim-telescope/telescope.nvim',
		config = function()
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
		end,
		dependencies = { 'nvim-lua/plenary.nvim', 'kyazdani42/nvim-web-devicons' }
	},
	-- Automatic pairs of ( [ { insertion
	{ 'windwp/nvim-autopairs', config = true },
	-- Add a fancy file explorer
	{ 'nvim-tree/nvim-tree.lua',
		keys = {
			{ '<C-n>', '<cmd>NvimTreeToggle<CR>',		desc = 'Open [N]erd tree explorer' },
			{ '<leader>no', '<cmd>NvimTreeToggle<CR>',	desc = '[N]erd tree [O]pen explorer' }
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
			view = {
				mappings = {
					list = {
						{ key = 'è', action = 'cd' }
					}
				}
			},
			actions = { open_file = { quit_on_open = true } }
		},
		dependencies = 'kyazdani42/nvim-web-devicons'
	},
	-- add the vmap gl<SYMBOL> to vertical align to the given symbol
	{ 'tommcdo/vim-lion',
		config = function()
			vim.g.lion_squeeze_spaces = 1		-- Squeeze extra spaces when doing a vertical alignment
		end
	},
	-- Automatic white spaces trimming
	{ 'ntpeters/vim-better-whitespace',
		lazy = false,
		config = function()
			vim.g.better_whitespace_enabled = 1	-- Enable the plugin
			vim.g.strip_whitespace_on_save  = 1	-- Remove trailing white spaces on save
			vim.g.strip_whitespace_confirm  = 0	-- Disable the confirmation message on stripping white spaces
		end
	},
	-- CSV file handling
	{ 'chrisbra/csv.vim',
		config = function()
			vim.b.csv_arrange_align = 'lc.'		-- Left align when using ArrangeColumn in a csv file
		end
	},
	-- Deprecated LSP Functionnalities (used only for spell checking)
	{ 'neoclide/coc.nvim',
		keys = {
			{ '<leader>ac', '<Plug>(coc-codeaction-selected)w',		desc = 'Replace the [c]urrent word (normal mode)' },
			{ '<leader>ac', '<Plug>(coc-codeaction-selected)w', mode = 'v', desc = 'Replace the [c]urrent word (visual mode)' },
			{ '[s',		'<Plug>(coc-diagnostic-prev)',			desc = 'Jump to the previous [S]pelling mistakes' },
			{ ']s',		'<Plug>(coc-diagnostic-next)',			desc = 'Jump to the next [S]pelling mistakes' }
		},
		cmd = { 'CocUpdate', 'CocUpdateSync' },
		branch = 'release',
		config = function() vim.g.coc_global_extensions = { 'coc-cspell-dicts', 'coc-spell-checker' } end
	},
	-- LSP Configuration & Plugins
	{ 'neovim/nvim-lspconfig',
		lazy = false,
		keys = { { '<leader>mo', ':Mason<CR>', desc = '[M]ason [O]pen' } },
		config = function()
			require('neodev').setup()		-- Setup neovim lua configuration
			require('mason').setup()		-- Setup mason so it can manage external tooling
			require('fidget').setup()		-- Turn on lsp status information

			-- Enable the following language servers with overriding configuration
			local servers = {
				lua_ls = {
					Lua = {
						workspace = { checkThirdParty = false },
						telemetry = { enable = false }
					}
				}
			}

			local on_attach = function(_, bufnr)
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

				nmap('<leader>rn', vim.lsp.buf.rename,							'LSP: [R]e[n]ame', bufnr)
				nmap('<leader>ca', vim.lsp.buf.code_action,						'LSP: [C]ode [A]ction', bufnr)
				nmap('gd',	   vim.lsp.buf.definition,						'LSP: [G]oto [D]efinition', bufnr)
				nmap('gr',	   require('telescope.builtin').lsp_references,				'LSP: [G]oto [R]eferences', bufnr)
				nmap('gI',	   vim.lsp.buf.implementation,						'LSP: [G]oto [I]mplementation', bufnr)
				nmap('<leader>D',  vim.lsp.buf.type_definition,						'LSP: Type [D]efinition', bufnr)
				nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols,			'LSP: [D]ocument [S]ymbols', bufnr)
				nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols,		'LSP: [W]orkspace [S]ymbols', bufnr)
				nmap('<leader>db', dap.toggle_breakpoint,						'[D]ebug toggle [B]reakpoint]', bufnr)
				nmap({ '<leader>dc', '<F5>' }, dap.continue,						'[D]ebug [C]ontinue', bufnr)
				nmap({ '<leader>do', '<F10>' }, dap.step_over,						'[D]ebug Step [O]ver', bufnr)
				nmap({ '<leader>di', '<F11>' }, dap.step_into,						'[D]ebug Step [I]nto', bufnr)
				nmap({ '<leader>dO', '<F12>' }, dap.step_out,						'[D]ebug Step [O]ut', bufnr)
				nmap({ '<leader>dt', '<S-F5>' }, dap.terminate,						'[D]ebug [T]erminate', bufnr)
				nmap({ '<leader>dr', '<C-F5>' }, function() dap.terminate(); dap.continue(); end,	'[D]ebug [R]estart', bufnr)
				nmap('K',	   vim.lsp.buf.hover,							'LSP: Hover Documentation', bufnr)
				nmap('<M-k>',	   vim.lsp.buf.signature_help,						'LSP: Signature Documentation', bufnr)
				nmap('gD',	   vim.lsp.buf.declaration,						'LSP: [G]oto [D]eclaration', bufnr)
				nmap('<leader>du', dapui.toggle,							'[D]ebug toggle [U]I', bufnr)
				nmap('[d',	   vim.diagnostic.goto_prev,						'LSP: Jump to previous [D]iagnostics', bufnr)
				nmap(']d',	   vim.diagnostic.goto_next,						'LSP: Jump to next [D]iagnostics', bufnr)

				dap.adapters.cppdbg = {
					id = 'cppdbg',
					type = 'executable',
					command = vim.fn.stdpath 'data' .. '/mason/bin/OpenDebugAD7'
				}
				dap.configurations.cpp = {
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
				}
				dap.adapters.debugpy = {
					id = 'debugpy',
					type = 'executable',
					command = vim.fn.stdpath 'data' .. '/mason/bin/debugpy-adapter'
				}
				dap.configurations.python = {
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
			end

			local mason_lspconfig = require('mason-lspconfig')
			mason_lspconfig.setup {
				ensure_installed = vim.tbl_keys(servers)
			}

			local lspconfig = require('lspconfig')
			local root_pattern = lspconfig.util.root_pattern;
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

			mason_lspconfig.setup_handlers {
				function(server_name)
					lspconfig[server_name].setup {
						capabilities = capabilities,
						on_attach = on_attach,
						settings = servers[server_name]
					}
				end
			}
			lspconfig['ccls'].setup({
				cmd = { 'ccls' },
				filetypes = { 'c', 'cpp', 'cuda', 'objc', 'objcpp' },
				init_options = { clang = { extraArgs = { '-std=c++17' }} },
				capabilities = capabilities,
				on_attach = on_attach
			})
			lspconfig['hls'].setup({
				cmd = { 'haskell-language-server-wrapper', '--lsp' },
				filetypes = { 'haskell', 'lhaskell', 'cabal' },
				root_dir = root_pattern('*.cabal', 'stack.yaml', 'cabal.project', 'package.yaml', 'hie.yaml'),
				capabilities = capabilities,
				on_attach = on_attach
			})
		end,
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			'williamboman/mason.nvim', 'williamboman/mason-lspconfig.nvim',

			-- Useful status updates for LSP
			'j-hui/fidget.nvim',

			-- Additional lua configurations, make nvim stuff amazing
			'folke/neodev.nvim',

			-- Auto completion functionnalities
			'hrsh7th/cmp-nvim-lsp',

			-- Debugging purposes
			'mfussenegger/nvim-dap', 'rcarriga/nvim-dap-ui'
		}
	},
	-- Autocompletion
	{ 'hrsh7th/nvim-cmp',
		event = "InsertEnter",
		config = function()
			local cmp = require('cmp')
			local luasnip = require('luasnip')

			cmp.setup {
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end
				},
				mapping = cmp.mapping.preset.insert {
					['<C-d>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<CR>'] = cmp.mapping.confirm {
						behavior = cmp.ConfirmBehavior.Replace,
						select = true
					},
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
				},
				sources = { { name = 'nvim_lsp' }, { name = 'luasnip' } }
			}
		end,
		dependencies = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip' }
	},
	-- Allow the use of formatter managed by Mason
	{ 'mhartington/formatter.nvim',
		keys = { { '<leader>f', '<cmd>Format<CR>', desc = '[F]ormat the current document' } },
		-- TODO Add Formater usage
		-- TODO Add linter usage
		--config = function()
		--	-- Create a command `:Format` local to the LSP buffer
		--	vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_) vim.lsp.buf.format() end,
		--		{ desc = 'Format current buffer with LSP' })
		--end,
		dependencies = 'williamboman/mason.nvim'
	},
	-- Allow use of background jobs
	{ 'tpope/vim-dispatch',
		keys = {
			{'<leader>tp', ':Dispatch! make preview<CR>', desc = 'La[T]eX [P]review document'},
			-- TUI programs
			{'<leader>$g', ':Start lazygit<CR>',    desc = 'Open Lazy[G]it'},
			{'<leader>$d', ':Start lazydocker<CR>', desc = 'Open Lazy[D]ocker'}
		},
		config = function()
			Autocmd('BufWritePost', '*.tex', function() vim.cmd('Spawn! make -j $NPROC') end)		-- Auto compile LaTeX document on save
		end,
		cmd = { 'Dispatch', 'Make', 'Focus', 'Start', 'Spawn' }
	},
	-- Highlight, edit, and navigate code
	{ 'nvim-treesitter/nvim-treesitter',
		config = function()
			require('nvim-treesitter.configs').setup({
				-- Add languages to be installed here that you want installed for treesitter
				ensure_installed = { 'c', 'cpp', 'cuda', 'lua', 'python', 'help', 'haskell', 'javascript', 'typescript' },
				highlight = { enable = true },
				rainbow = { enable = true },
				indent = { enable = false },
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = '<c-space>',
						node_incremental = '<c-space>',
						scope_incremental = '<c-s>',
						node_decremental = '<c-backspace>'
					}
				},
				textobjects = {
					select = {
						enable = true,
						lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							['aa'] = '@parameter.outer',
							['ia'] = '@parameter.inner',
							['af'] = '@function.outer',
							['if'] = '@function.inner',
							['ac'] = '@class.outer',
							['ic'] = '@class.inner'
						}
					},
					move = {
						enable = true,
						set_jumps = true, -- whether to set jumps in the jumplist
						goto_next_start = {
							[']m'] = '@function.outer',
							[']]'] = '@class.outer'
						},
						goto_next_end = {
							[']M'] = '@function.outer',
							[']['] = '@class.outer'
						},
						goto_previous_start = {
							['[m'] = '@function.outer',
							['[['] = '@class.outer'
						},
						goto_previous_end = {
							['[M'] = '@function.outer',
							['[]'] = '@class.outer'
						}
					},
					swap = {
						enable = true,
						swap_next = {
							['<leader>a'] = '@parameter.inner'
						},
						swap_previous = {
							['<leader>A'] = '@parameter.inner'
						}
					}
				}
			})
		end,
		build = function()
			pcall(require('nvim-treesitter.install').update { with_sync = true })
		end,
		dependencies = {
			-- Colourize multiple inner level to ( [ {
			'p00f/nvim-ts-rainbow',
			-- Additional text objects via treesitter
			'nvim-treesitter/nvim-treesitter-textobjects',
			-- Display code context
			'nvim-treesitter/nvim-treesitter-context'
		}
	},
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
	-- Show a toggable undotree
	{ 'mbbill/undotree', keys = { { '<leader>ut', '<Cmd>UndotreeToggle<CR>', desc = 'Open [U]ndo [T]ree' } } },
	-- Display a popup with possible key bindings of the command you started typing
	{ 'folke/which-key.nvim',
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 200
			require('which-key').setup({})
		end
	}
})
local lazy = require('lazy')
nmap('<leader>lo', lazy.home,		'[L]azy [O]pen home')
nmap('<leader>lb', lazy.build,		'[L]azy [B]uild')
nmap('<leader>lc', lazy.check,		'[L]azy [C]heck')
nmap('<leader>lC', lazy.clean,		'[L]azy [C]lean')
nmap('<leader>lt', lazy.clear,		'[L]azy clear [T]asks')
nmap('<leader>lH', lazy.health,		'[L]azy [H]ealth')
nmap('<leader>lh', lazy.help,		'[L]azy [H]elp')
nmap('<leader>li', lazy.install,	'[L]azy [I]nstall')
nmap('<leader>lu', lazy.update,		'[L]azy [U]pdate')
nmap('<leader>ls', lazy.sync,		'[L]azy [S]ync')
nmap('<leader>lr', lazy.restore,	'[L]azy [R]estore')
nmap('<leader>lp', lazy.profile,	'[L]azy [P]rofile')
nmap('<leader>ll', lazy.log,		'[L]azy [L]og')
nmap('<leader>lL', lazy.load,		'[L]azy [L]oad')
nmap('<leader>ld', lazy.debug,		'[L]azy [D]ebug')

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- General settings configuration
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vim.o.mouse					= 'a'										-- Enable mouse mode (selection, scrolling etc.)
vim.o.termguicolors				= true										-- Enable 24-bit RGB colours in the terminal
vim.o.syntax					= true										-- Enables syntax highlighting
vim.o.listchars					= 'eol:﬋,tab:→ ,trail:•,extends:>,precedes:<,space:·,nbsp:ﴔ'			-- List of whitespace characters replacement (see :h listchars)
vim.o.list					= true										-- Enable replacement of listchars
vim.o.hidden					= true										-- Required to keep multiple buffers open multiple buffers
vim.o.wrap					= false										-- Display long lines as just one line
vim.o.encoding					= 'UTF-8'									-- The encoding displayed
vim.o.fileencoding				= 'UTF-8'									-- The encoding written to file
vim.o.ruler					= true										-- Show the cursor position all the time
vim.o.iskeyword					= vim.o.iskeyword .. ',-'							-- treat dash separated words as a word text object
vim.o.tabstop					= 8										-- Set the width of a tab
vim.o.shiftwidth				= 8										-- Change the number of space characters inserted for indentation
vim.o.softtabstop				= 8										-- Change the number of space characters inserted for indentation
vim.o.smartindent				= true										-- Does smart autoindenting when starting a new line
vim.o.expandtab					= false										-- Disable the tab expansion of spaces
vim.o.number					= true										-- Line numbers
vim.o.relativenumber				= true										-- Relative number (enabled after number for hybrid mode)
vim.o.cursorline				= true										-- Enable highlighting of the current line
vim.o.cursorcolumn				= true										-- Enable highlighting of the current column
vim.o.showtabline				= 2										-- Always show top files tabs
vim.o.showmode					= false										-- We don't need to see things like -- INSERT -- any more
vim.o.clipboard					= 'unnamedplus'									-- Copy paste between vim and everything else
vim.o.foldmethod				= 'syntax'									-- Change the folding method to fold from { [ ...
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
vim.o.wildignore				= vim.o.wildignore .. '*/node_modules/*,*/.git/*,*/venv/*,*/package-lock.json'	-- Ignore files in fuzzy finder
vim.o.undofile					= true										-- Enable undofile to save undos after exit
Autocmd('Filetype', 'tex',			function() vim.o.wrap = true end)						-- Enable wraping only for LaTeX files
Autocmd('Filetype', 'python',			function() vim.o.expandtab = false end)						-- Disable the tab expansion of spaces
Autocmd({ 'BufRead', 'BufNewFile' }, '*.tex',	function() vim.o.filetype = 'tex' end)						-- Sometimes LaTeX isn't properly recognized

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Key mapping configuration
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
nmap('<C-s>', ':w<CR>',														   'Save buffer shortcut')
nmap({ '<C-F4>', '<F28>' }, ':q!<CR>',												   'Close window shortcut (keeps buffer open)')
nmap({ '<S-F4>', 'F16' }, ':bd<CR>',												   'Close buffer shortcut')
nmap('<M-j>', ':resize -1<CR>',													   'Decrease buffer window horizontal size (M is the ALT modifier key)')
nmap('<M-k>', ':resize +1<CR>',													   'Increase buffer window horizontal size (M is the ALT modifier key)')
nmap('<M-h>', ':vertical resize -1<CR>',											   'Decrease buffer window vertical size (M is the ALT modifier key)')
nmap('<M-l>', ':vertical resize +1<CR>',											   'Increase buffer window vertical size (M is the ALT modifier key)')
map('t', '<Esc>', '<C-\\><C-n>',												   'Fix terminal exit button')
nmap({'<C-m>', '<CR>'}, ':noh<CR>',												   'Clear the highlighting of :set hlsearch (<C-M> == <CR> in st)')
nmap('<C-z>', '<Nop>',														   'Disable the suspend signal')
vmap('<', '<gv',														   'Shift the selection one indent to the right')
vmap('>', '>gv',														   'Shift the selection one indent to the left')
nmap('<F2>',															   ':set invpaste paste?<CR>', 'Toggle clipboard pasting')
nmap('<C-J>',															   'ddp', 'Move the current line down')
nmap('<C-K>',															   'ddkkp', 'Move the current line up')
vim.api.nvim_create_user_command('EditConfig', 'e ' .. vim.fn.stdpath 'config' .. '/init.lua', { desc =				   'Edit Neovim config file' })
vim.api.nvim_create_user_command('EspansoEdit', 'e ' .. vim.fn.stdpath 'config' .. '../espanso/match/base.yml', { desc =	   'Edit Espanso config file' })

