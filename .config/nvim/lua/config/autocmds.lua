local group = vim.api.nvim_create_augroup("vimrc", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then
      return
    end

    local path = vim.api.nvim_buf_get_name(args.buf)
    if path == "" then
      return
    end

    local dir = vim.fn.fnamemodify(path, ":p:h")
    if dir ~= "" and vim.fn.isdirectory(dir) == 1 then
      vim.cmd.lcd(vim.fn.fnameescape(dir))
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "cs",
  callback = function(args)
    vim.bo[args.buf].commentstring = "//// %s"
  end,
})
