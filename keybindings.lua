local keybindings = {}

function register_buffer_keybindings()
  vim.keymap.set('n', 'bn', function() vim.cmd("bn") end)
  vim.keymap.set('n', 'bp', function() vim.cmd("bp") end)
  vim.keymap.set('n', 'bd', function() vim.cmd("bd") end)
  vim.keymap.set('n', 'bc', require('misc.buffers').buffer_choose)
end

function keybindings.register()
  register_buffer_keybindings()
end

return keybindings
