return {
  {
    "fatih/vim-go",
    ft = "go",
    init = function()
      vim.g.go_gopls_enabled = 0
      vim.g.go_def_mapping_enabled = 0
    end,
  },
  {
    "charlespascoe/vim-go-syntax",
    ft = "go",
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    build = function()
      if vim.fn.executable("npm") == 0 then
        vim.notify("markdown-preview.nvim needs npm for its installer. Install npm, then run :Lazy build markdown-preview.nvim.", vim.log.levels.WARN)
        return
      end
      vim.fn["mkdp#util#install"]()
    end,
  },
}
