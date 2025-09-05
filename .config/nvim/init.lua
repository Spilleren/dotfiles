-- Check if running in Neovim
if vim.fn.has('nvim') == 0 then
    return
end

-- Declare group for autocmd and clear it
vim.api.nvim_create_augroup('vimrc', { clear = true })

-- Leader key configuration
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- General settings
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.hidden = true
vim.opt.signcolumn = 'yes:2'
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.spell = true
vim.opt.title = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wildmode = {'longest:full', 'full'}
vim.opt.wrap = false
vim.opt.list = true
vim.opt.mouse = 'a'
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.joinspaces = false
vim.opt.splitright = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.confirm = true
vim.opt.exrc = true
vim.opt.hidden = true
vim.opt.cmdheight = 2
vim.opt.updatetime = 300
vim.opt.shortmess:append('c')

-- Plugin configuration using vim-plug
vim.cmd([[
call plug#begin('~/.vim/plugged')

Plug 'fatih/vim-go'
Plug 'neoclide/coc.nvim', {'do': 'npm install --frozen-lockfile'}
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdtree'
Plug 'stsewd/fzf-checkout.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'nvim-lua/plenary.nvim'
Plug 'NeogitOrg/neogit'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'akinsho/toggleterm.nvim'
Plug 'charlespascoe/vim-go-syntax'
Plug 'devsjc/vim-jb'
Plug 'doums/darcula'
Plug 'justinmk/vim-sneak'

call plug#end()
]])

require("toggleterm").setup{
  shell = "zsh",  -- Set the shell to zsh
  -- other configurations can go here 
  direction = "float",  -- Use floating window for the terminal
  size = 20,  -- Size of the terminal window
}
-- Apply color scheme
vim.cmd('colorscheme darcula')

-- Coc.nvim configuration
vim.api.nvim_set_keymap('i', '<TAB>', 'coc#pum#visible() ? coc#pum#next(1) : CheckBackspace() ? "\\<Tab>" : coc#refresh()', { noremap = true, silent = true, expr = true })
vim.api.nvim_set_keymap('i', '<S-TAB>', 'coc#pum#visible() ? coc#pum#prev(1) : "\\<C-h>"', { noremap = true, expr = true })
vim.api.nvim_set_keymap('i', '<c-space>', 'coc#refresh()', { noremap = true, silent = true, expr = true })
vim.api.nvim_set_keymap('n', '[c', '<Plug>(coc-diagnostic-prev)', { silent = true })
vim.api.nvim_set_keymap('n', ']c', '<Plug>(coc-diagnostic-next)', { silent = true })
vim.api.nvim_set_keymap('n', '<leader>gd', '<Plug>(coc-definition)', { silent = true })
vim.api.nvim_set_keymap('n', '<leader>gy', '<Plug>(coc-type-definition)', { silent = true })
vim.api.nvim_set_keymap('n', '<leader>gi', '<Plug>(coc-implementation)', { silent = true })
vim.api.nvim_set_keymap('n', '<leader>gr', '<Plug>(coc-references)', { silent = true })
vim.api.nvim_set_keymap('n', '<leader>rn', '<Plug>(coc-rename)', { silent = true })
vim.api.nvim_set_keymap('v', '<leader>f', '<Plug>(coc-format-selected)', {})
vim.api.nvim_set_keymap('n', '<leader>f', '<Plug>(coc-format-selected)', {})
vim.api.nvim_set_keymap('n', '<space>a', ':<C-u>CocList diagnostics<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<space>e', ':<C-u>CocList extensions<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<space>c', ':<C-u>CocList commands<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<space>o', ':<C-u>CocList outline<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<space>s', ':<C-u>CocList -I symbols<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<space>j', ':<C-u>CocNext<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<space>k', ':<C-u>CocPrev<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<space>p', ':<C-u>CocListResume<CR>', { noremap = true, silent = true })

-- FZF settings
vim.g.fzf_layout = { up = '~90%', window = { width = 0.8, height = 0.8, yoffset = 0.5, xoffset = 0.5 } }
vim.env.FZF_DEFAULT_OPTS = '--layout=reverse --info=inline'

-- Custom commands using FZF
vim.api.nvim_create_user_command('Files', function(opts)
    vim.fn['fzf#run'](vim.fn['fzf#wrap']('files', vim.fn['fzf#vim#with_preview']({ dir = opts.args, sink = 'e', source = 'rg --files --hidden' }), opts.bang))
end, { bang = true, nargs = '?', complete = 'dir' })

vim.api.nvim_create_user_command('AllFiles', function(opts)
    vim.fn['fzf#run'](vim.fn['fzf#wrap']('allfiles', vim.fn['fzf#vim#with_preview']({ dir = opts.args, sink = 'e', source = 'rg --files --hidden --no-ignore' }), opts.bang))
end, { bang = true, nargs = '?', complete = 'dir' })

-- Key mappings for FZF and NERDTree
vim.api.nvim_set_keymap('n', '<leader>f', ':Files<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>F', ':AllFiles<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>b', ':Buffers<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>h', ':History<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>r', ':Rg<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>R', ':Rg<space>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gb', ':GBranches<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>n', ':NERDTreeFocus<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>x', ':NERDTree<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-f>', ':NERDTreeFind<CR>', { noremap = true, silent = true })

-- Key mapping to toggle the terminal in normal mode
vim.api.nvim_set_keymap('n', '<F12>', '<cmd>ToggleTerm<CR>', { noremap = true, silent = true })

-- Key mapping to toggle the terminal in terminal mode
vim.api.nvim_set_keymap('t', '<F12>', '<cmd>ToggleTerm<CR>', { noremap = true, silent = true })

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
})
