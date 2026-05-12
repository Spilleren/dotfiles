vim.api.nvim_create_user_command('RunSh', function()
  vim.opt.splitright = true
  vim.cmd('vnew')
  vim.bo.filetype = 'sh'
  vim.cmd('read !sh #')
end, {})
