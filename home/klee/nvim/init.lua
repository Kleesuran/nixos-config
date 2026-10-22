--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||    (DevOps Mod)    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

This is a customized Neovim configuration based on kickstart.nvim,
tailored for DevOps development and migrated from VSCode Insiders.

--]]

-- ============================================================
-- SECTION 1: FOUNDATION
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()

  -- Set <space> as the leader key
  -- See `:help mapleader`
  -- NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Set to true since Maple Mono/JetBrainsMono Nerd Fonts are installed on the host
  vim.g.have_nerd_font = true

  -- [[ Setting options ]]
  -- See `:help vim.o`
  -- NOTE: Customized based on VSCode Insiders settings.json
  
  -- Make line numbers default
  vim.o.number = true
  vim.o.relativenumber = false -- Match VSCode's standard line numbers

  -- Enable mouse mode, can be useful for resizing splits for example!
  vim.o.mouse = 'a'

  -- Don't show the mode, since it's already in the status line
  vim.o.showmode = false

  -- Sync clipboard between OS and Neovim.
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Enable break indent
  vim.o.breakindent = true

  -- Enable undo/redo changes even after closing and reopening a file
  vim.o.undofile = true

  -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
  vim.o.ignorecase = true
  vim.o.smartcase = true

  -- Keep signcolumn on by default
  vim.o.signcolumn = 'yes'

  -- Decrease update time
  vim.o.updatetime = 250

  -- Decrease mapped sequence wait time
  vim.o.timeoutlen = 300

  -- Configure how new splits should be opened
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- Sets how neovim will display certain whitespace characters in the editor.
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  -- Preview substitutions live, as you type!
  vim.o.inccommand = 'split'

  -- Show which line your cursor is on
  vim.o.cursorline = true

  -- Minimal number of screen lines to keep above and below the cursor.
  vim.o.scrolloff = 10

  -- Raise a dialog asking if you wish to save the current file(s) on unsaved quit
  vim.o.confirm = true

  -- Enable word wrapping (VSCode "editor.wordWrap": "on")
  vim.o.wrap = true

  -- Set tab size to 2 spaces and disable auto-indent-detection to force this style
  -- (VSCode "editor.tabSize": 2, "editor.insertSpaces": true, "editor.detectIndentation": false)
  vim.o.tabstop = 2
  vim.o.shiftwidth = 2
  vim.o.softtabstop = 2
  vim.o.expandtab = true

  -- Display rulers at 80 and 120 characters (VSCode "editor.rulers": [80, 120])
  vim.opt.colorcolumn = { "80", "120" }

  -- Set font for GUI clients like Neovide
  vim.o.guifont = "Maple Mono Normal NL NF CN:h14,JetBrainsMono Nerd Font Mono:h14"

  -- Set Podman specific DOCKER_HOST (VSCode "DOCKER_HOST": "unix:///run/user/1000/podman/podman.sock")
  vim.env.DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock"

  -- Add OpenCode CLI path to Neovim PATH
  vim.env.PATH = vim.fn.expand("$HOME/.opencode/bin:") .. vim.env.PATH

  -- [[ Basic Keymaps ]]
  -- See `:help vim.keymap.set()`

  -- Clear highlights on search when pressing <Esc> in normal mode
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Diagnostic Config & Keymaps
  -- Customized to match ErrorLens ("errorLens.enabledDiagnosticLevels": ["error", "warning"])
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },
    
    -- Virtual text diagnostics (similar to ErrorLens) restricted to Errors & Warnings
    virtual_text = {
      severity = { min = vim.diagnostic.severity.WARN },
      spacing = 4,
      prefix = '●',
    },
    
    -- Set Diagnostic signs in the gutter
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = '',
        [vim.diagnostic.severity.WARN] = '',
        [vim.diagnostic.severity.INFO] = '',
        [vim.diagnostic.severity.HINT] = '󰠠',
      },
    },

    -- Auto open the float when jumping diagnostics
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  -- Exit terminal mode easily
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- Keybinds to make split navigation easier.
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- [[ Basic Autocommands ]]
  -- See `:help lua-guide-autocommands`

  -- Highlight when yanking (copying) text
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })

  -- Automatically trim trailing whitespaces on save (VSCode "files.trimTrailingWhitespace": true)
  vim.api.nvim_create_autocmd('BufWritePre', {
    desc = 'Trim trailing whitespace on save',
    group = vim.api.nvim_create_augroup('kickstart-trim-whitespace', { clear = true }),
    callback = function()
      if vim.bo.modifiable then
        local save = vim.fn.winsaveview()
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.winrestview(save)
      end
    end,
  })
end

-- ============================================================
-- SECTION 2: PLUGIN MANAGER INTRO
-- vim.pack intro, build hooks
-- ============================================================
do
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- Auto build plugins when installed/updated
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---Helper to construct github URLs
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 3: UI / CORE UX PLUGINS
-- catppuccin, gitsigns, which-key, todo-comments, mini modules, neo-tree, lazygit, kulala
-- ============================================================
do
  -- Install icons if we have a Nerd Font
  if vim.g.have_nerd_font then vim.pack.add { gh 'nvim-tree/nvim-web-devicons' } end

  -- Gitsigns: Git integration + inline blame (VSCode GitLens)
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
    current_line_blame = true, -- Shows current line git blame (like GitLens)
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = 'eol',
      delay = 1000,
      ignore_whitespace = false,
    },
  }

  -- Which-key: Shows pending keybindings
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
      { '<leader>l', group = '[L]azyGit' },
    },
  }

  -- Catppuccin theme (Light theme: Catppuccin Latte)
  vim.pack.add { gh 'catppuccin/nvim' }
  require('catppuccin').setup {
    flavour = 'latte', -- Load Catppuccin Latte (light theme)
    integrations = {
      blink_cmp = true,
      gitsigns = true,
      mini = true,
      neotree = true,
      which_key = true,
      treesitter = true,
    }
  }
  vim.o.background = 'light' -- Tell Neovim to optimize UI for light backgrounds
  vim.cmd.colorscheme 'catppuccin'

  -- Todo-comments: Highlight TODO/FIXME/NOTE (VSCode Better Comments)
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { 
    signs = vim.g.have_nerd_font,
  }

  -- [[ mini.nvim ]]
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- Better around/inside text objects
  require('mini.ai').setup {
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  require('mini.surround').setup()

  -- Autopairs (VSCode automatic bracket closing)
  require('mini.pairs').setup()

  -- Vertical indent lines (VSCode indent guide lines)
  require('mini.indentscope').setup()

  -- Simple statusline
  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end

  -- [[ Neo-tree ]]
  -- Sidebar file explorer (VSCode Explorer sidebar)
  vim.pack.add {
    gh 'nvim-neo-tree/neo-tree.nvim',
    gh 'MunifTanjim/nui.nvim',
  }
  require('neo-tree').setup {
    close_if_last_window = true,
    filesystem = {
      filtered_items = {
        visible = true,
        show_hidden_dotfiles = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      follow_current_file = {
        enabled = true,
      },
    },
  }
  vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<cr>', { desc = 'Toggle [E]xplorer (Neo-tree)' })

  -- [[ LazyGit ]]
  -- TUI Git integration (VSCode Source Control replacement)
  vim.pack.add { gh 'kdheepak/lazygit.nvim' }
  vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = 'Toggle [L]azy[G]it' })

  -- [[ Kulala ]]
  -- HTTP Client for API testing (VSCode Thunder Client replacement)
  vim.pack.add { gh 'mistweaverco/kulala.nvim' }
  require('kulala').setup {}
  vim.keymap.set('n', '<leader>R', function() require('kulala').run() end, { desc = 'Run HTTP [R]equest under cursor' })

  -- [[ Dashboard ]]
  -- Start screen menu (LazyVim style)
  vim.pack.add { gh 'nvimdev/dashboard-nvim' }
  require('dashboard').setup {
    theme = 'doom',
    config = {
      header = {
        "",
        "██╗  ██╗██╗ ██████╗██╗  ██╗███████╗████████╗ █████╗ ██████╗ ████████╗",
        "██║ ██╔╝██║██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝",
        "█████╔╝ ██║██║     █████╔╝ ███████╗   ██║   ███████║██████╔╝   ██║   ",
        "██╔═██╗ ██║██║     ██╔═██╗ ╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ",
        "██║  ██╗██║╚██████╗██║  ██╗███████║   ██║   ██║  ██║██║  ██║   ██║   ",
        "╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ",
        "",
        "              ⚡ Customized DevOps Environment ⚡              ",
        "",
      },
      center = {
        { icon = '  ', icon_hl = 'Title', desc = 'Find File          ', action = 'Telescope find_files', key = 'f' },
        { icon = '  ', icon_hl = 'Title', desc = 'Recent Files       ', action = 'Telescope oldfiles', key = 'r' },
        { icon = '  ', icon_hl = 'Title', desc = 'Find Text          ', action = 'Telescope live_grep', key = 'g' },
        { icon = '  ', icon_hl = 'Title', desc = 'Configuration      ', action = 'edit ' .. vim.fn.stdpath('config') .. '/init.lua', key = 'c' },
        { icon = '󰚰  ', icon_hl = 'Title', desc = 'Update Plugins     ', action = 'lua vim.pack.update()', key = 'u' },
        { icon = '󰈆  ', icon_hl = 'Title', desc = 'Quit Neovim        ', action = 'qa', key = 'q' },
      },
      footer = {
        "",
        "Neovim is ready. Happy hacking!",
      }
    }
  }

  -- [[ Dressing ]]
  -- Better Neovim inputs and selects UI (required for CodeCompanion prompts)
  vim.pack.add { gh 'stevearc/dressing.nvim' }
  require('dressing').setup {}

  -- [[ CodeCompanion ]]
  -- AI Coding Assistant using Gemini and OpenAI
  vim.pack.add { gh 'nvim-lua/plenary.nvim' } -- Ensure plenary is loaded first!
  vim.pack.add { gh 'olimorris/codecompanion.nvim' }
  require('codecompanion').setup {
    strategies = {
      chat = {
        adapter = 'gemini', -- Default chat adapter
      },
      inline = {
        adapter = 'gemini', -- Default inline adapter
      },
    },
    adapters = {
      gemini = function()
        return require('codecompanion.adapters').extend('gemini', {
          env = {
            api_key = 'GEMINI_API_KEY', -- Reads from GEMINI_API_KEY environment variable
          },
        })
      end,
      openai = function()
        return require('codecompanion.adapters').extend('openai', {
          env = {
            api_key = 'OPENAI_API_KEY', -- Reads from OPENAI_API_KEY environment variable
          },
        })
      end,
    },
  }

  -- Keybindings for CodeCompanion AI
  vim.keymap.set({ 'n', 'v' }, '<C-a>', '<cmd>CodeCompanionActions<cr>', { desc = 'AI Actions' })
  vim.keymap.set({ 'n', 'v' }, '<leader>a', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'AI Chat' })
  vim.keymap.set('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { desc = 'Add selected to AI Chat' })

  -- [[ OpenCode ]]
  -- AI Agentic Coding Integration
  vim.pack.add { gh 'sudo-tee/opencode.nvim' }
  require('opencode').setup {}

  -- Keybinding for OpenCode
  vim.keymap.set({ 'n', 'v' }, '<leader>o', '<cmd>Opencode<cr>', { desc = 'Toggle [O]penCode' })
end

-- ============================================================
-- SECTION 4: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================
do
  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

  vim.pack.add(telescope_plugins)

  require('telescope').setup {
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })

  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  vim.keymap.set('n', '<leader>s/', function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end, { desc = '[S]earch [/] in Open Files' })

  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
end

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  -- Fidget: LSP progress status UI
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  -- SchemaStore: YAML & JSON Schemas (for Kubernetes, Docker Compose, Actions, etc.)
  vim.pack.add { gh 'b0o/SchemaStore.nvim' }

  -- Enable language servers relevant to DevOps & web development
  ---@type table<string, vim.lsp.Config>
  local servers = {
    -- Python
    pyright = {},
    -- Shell/Bash
    bashls = {},
    -- Terraform
    terraformls = {},
    -- Ansible
    ansiblels = {},
    -- Docker
    dockerls = {},
    docker_compose_language_service = {},
    -- Go
    gopls = {},
    -- JSON
    jsonls = {
      settings = {
        json = {
          schemas = require('schemastore').json.schemas(),
          validate = { enable = true },
        },
      },
    },
    -- ESLint / JS
    eslint = {},

    -- YAML with SchemaStore (Kubernetes schema auto-applied to yaml files)
    yamlls = {
      settings = {
        yaml = {
          schemaStore = {
            enable = false,
            avoidTypeError = true,
          },
          schemas = require('schemastore').yaml.schemas(),
        },
      },
    },

    -- Lua LSP Config
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false
        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end
        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      settings = {
        Lua = {
          format = { enable = false },
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  require('mason').setup {}

  -- Ensure the servers and helper lint/format tools are installed
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    'stylua',        -- Lua formatter
    'black',         -- Python formatter
    'shfmt',         -- Shell/Bash formatter
    'prettier',      -- Prettier for JSON, JS, Yaml, Markdown
    'tflint',        -- Terraform linter
    'ansible-lint',  -- Ansible linter
    'shellcheck',    -- Bash linter
    'hadolint',      -- Dockerfile linter
  })

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 6: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
do
  -- Formatting via conform.nvim (VSCode "editor.formatOnSave": true)
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Exclude files where autoformat is too slow or intrusive
      local disable_filetypes = { c = true, cpp = true }
      local lsp_format_opt
      if disable_filetypes[vim.bo[bufnr].filetype] then
        lsp_format_opt = 'never'
      else
        lsp_format_opt = 'fallback'
      end
      return {
        timeout_ms = 1000,
        lsp_format = lsp_format_opt,
      }
    end,
    default_format_opts = {
      lsp_format = 'fallback',
    },
    -- Formatters mapping (VSCode language-specific defaultFormatters)
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'black' },
      sh = { 'shfmt' },
      bash = { 'shfmt' },
      shellscript = { 'shfmt' },
      javascript = { 'prettier' },
      typescript = { 'prettier' },
      json = { 'prettier' },
      jsonc = { 'prettier' },
      yaml = { 'prettier' },
      markdown = { 'prettier' },
      terraform = { 'terraform_fmt' },
      tf = { 'terraform_fmt' },
    },
  }

  vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
end

-- ============================================================
-- SECTION 7: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = {
      preset = 'default',
    },

    appearance = {
      nerd_font_variant = 'mono',
    },

    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'lua' },
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 8: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Ensure basic + DevOps parsers are installed
  local parsers = { 
    'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc',
    'dockerfile', 'yaml', 'terraform', 'hcl', 'json', 'python', 'go', 'make'
  }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    if not vim.treesitter.language.add(language) then return end
    vim.treesitter.start(buf, language)

    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 9: OPTIONAL EXAMPLES / NEXT STEPS
-- ============================================================
do
  -- Modeline: see `:help modeline`
  -- vim: ts=2 sts=2 sw=2 et
end
