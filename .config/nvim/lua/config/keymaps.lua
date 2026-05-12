local map = vim.keymap.set

local function opts(desc)
  return { silent = true, desc = desc }
end

function _G.CheckBackspace()
  local col = vim.fn.col(".") - 1
  return col == 0 or vim.fn.getline("."):sub(col, col):match("%s") ~= nil
end

-- Better defaults
map({ "n", "i", "s" }, "<C-s>", "<cmd>write<CR><Esc>", opts("Save file"))
map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts("Clear search highlight"))
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Native LSP completion
map("i", "<Tab>", [[pumvisible() ? "\<C-n>" : v:lua.CheckBackspace() ? "\<Tab>" : "\<C-x>\<C-o>"]], {
  noremap = true,
  silent = true,
  expr = true,
})
map("i", "<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<C-h>"]], { noremap = true, expr = true })
map("i", "<C-Space>", function()
  vim.lsp.completion.get()
end, opts("Trigger LSP completion"))

-- LazyVim-style top-level pickers
map("n", "<leader><space>", "<cmd>Files<CR>", opts("Find files"))
map("n", "<leader>,", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<CR>", opts("Switch buffer"))
map("n", "<leader>/", "<cmd>Telescope live_grep<CR>", opts("Grep"))
map("n", "<leader>:", "<cmd>Telescope command_history<CR>", opts("Command history"))

-- File/find
map("n", "<leader>f", "<nop>", { desc = "+file/find" })
map("n", "<leader>ff", "<cmd>Files<CR>", opts("Find files"))
map("n", "<leader>fF", "<cmd>AllFiles<CR>", opts("Find all files"))
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", opts("Recent files"))
map("n", "<leader>fn", "<cmd>enew<CR>", opts("New file"))

-- Search
map("n", "<leader>s", "<nop>", { desc = "+search" })
map("n", "<leader>sg", "<cmd>Telescope live_grep<CR>", opts("Grep"))
map("n", "<leader>sG", ":Rg ", { desc = "Grep with query" })
map("n", "<leader>sw", "<cmd>Telescope grep_string<CR>", opts("Word under cursor"))
map("n", "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", opts("Buffer lines"))
map("n", "<leader>ss", "<cmd>Telescope lsp_document_symbols<CR>", opts("Document symbols"))
map("n", "<leader>sS", "<cmd>Telescope lsp_workspace_symbols<CR>", opts("Workspace symbols"))

-- Buffers
map("n", "<leader>b", "<nop>", { desc = "+buffer" })
map("n", "<leader>bb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<CR>", opts("Switch buffer"))
map("n", "<leader>bd", "<cmd>bdelete<CR>", opts("Delete buffer"))
map("n", "<leader>bD", "<cmd>bdelete!<CR>", opts("Delete buffer force"))

-- Explorer
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", opts("Explorer"))
map("n", "<leader>E", "<cmd>NvimTreeFindFile<CR>", opts("Explorer current file"))

-- Git
map("n", "<leader>g", "<nop>", { desc = "+git" })
map("n", "<leader>gg", "<cmd>Neogit<CR>", opts("Neogit"))
map("n", "<leader>gs", "<cmd>Git<CR>", opts("Git status"))
map("n", "<leader>gb", "<cmd>Telescope git_branches<CR>", opts("Git branches"))
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", opts("Git commits"))

-- Diagnostics
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, opts("Previous diagnostic"))
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, opts("Next diagnostic"))
map("n", "<leader>x", "<nop>", { desc = "+diagnostics" })
map("n", "<leader>xx", "<cmd>Telescope diagnostics<CR>", opts("Workspace diagnostics"))
map("n", "<leader>xX", function()
  require("telescope.builtin").diagnostics({ bufnr = 0 })
end, opts("Buffer diagnostics"))

-- Terminal
map("n", "<leader>ft", "<cmd>ToggleTerm<CR>", opts("Terminal"))
map("n", "<F12>", "<cmd>ToggleTerm<CR>", opts("Toggle terminal"))
map("t", "<F12>", [[<C-\><C-n><cmd>ToggleTerm<CR>]], opts("Toggle terminal"))

-- Personal helpers
map("n", "<F5>", function()
  local saved_search = vim.fn.getreg("/")
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.setreg("/", saved_search)
end, opts("Remove trailing whitespace"))

-- Temporary compatibility aliases while switching muscle memory.
map("n", "<leader>F", "<cmd>AllFiles<CR>", opts("Find all files"))
map("n", "<leader>h", "<cmd>Telescope oldfiles<CR>", opts("Recent files"))
map("n", "<leader>r", "<cmd>Telescope live_grep<CR>", opts("Grep"))
map("n", "<leader>R", ":Rg ", { desc = "Grep with query" })
map("n", "<leader>n", "<cmd>NvimTreeFocus<CR>", opts("Focus explorer"))
map("n", "<C-f>", "<cmd>NvimTreeFindFile<CR>", opts("Explorer current file"))
