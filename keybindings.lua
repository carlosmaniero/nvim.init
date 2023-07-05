local keybindings = {}

function register_buffer_keybindings()
  vim.keymap.set('n', 'bn', function() vim.cmd("bn") end)
  vim.keymap.set('n', 'bp', function() vim.cmd("bp") end)
  vim.keymap.set('n', 'bd', function() vim.cmd("bd") end)
  vim.keymap.set('n', 'bc', require('misc.buffers').buffer_choose)
end

function register_bash_like_navigation_on_command_prompt()
  vim.api.nvim_set_keymap('c', '<C-A>', '<Home>',  {noremap = true})
  vim.api.nvim_set_keymap('c', '<C-E>', '<End>',   {noremap = true})
  vim.api.nvim_set_keymap('c', '<C-F>', '<Right>', {noremap = true})
  vim.api.nvim_set_keymap('c', '<C-B>', '<Left>',  {noremap = true})
  vim.api.nvim_set_keymap('c', '<C-N>', '<Down>',  {noremap = true})
  vim.api.nvim_set_keymap('c', '<C-P>', '<Up>',    {noremap = true})
end

function register_system_keybindings()
  vim.keymap.set('n', '<leader>sr', require('sys').reload_all)
end

function keybindings.register()
  register_buffer_keybindings()
  register_bash_like_navigation_on_command_prompt()
  register_system_keybindings()
end

return keybindings
