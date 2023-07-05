local system = {}

function system.reload_all()
  package.loaded = {}
  vim.cmd('source ~/.config/nvim/init.lua')
  print('Environment reloaded')
end

return system
