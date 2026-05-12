local opt = vim.opt

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.hidden = true
opt.signcolumn = "yes:2"
opt.relativenumber = true
opt.number = true
opt.termguicolors = true
opt.undofile = true
opt.spell = true
opt.title = true
opt.ignorecase = true
opt.smartcase = true
opt.wildmode = { "longest:full", "full" }
opt.wrap = false
opt.list = true
opt.mouse = "a"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.joinspaces = false
opt.splitright = true
opt.clipboard = "unnamedplus"
opt.confirm = true
opt.exrc = true
opt.cmdheight = 2
opt.updatetime = 300
opt.completeopt = { "menu", "menuone", "noselect", "popup" }
opt.shortmess:append("c")

vim.g.mkdp_auto_start = 1
vim.g.mkdp_echo_preview_url = 1

vim.o.shell = "pwsh"
vim.o.shellcmdflag = "-Command"
vim.o.shellquote = ""
vim.o.shellxquote = ""
