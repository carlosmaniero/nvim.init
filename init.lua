-- Get the current package path
local package_path = package.path

local config_dir = vim.fn.stdpath('config')

-- Add the path to the 'nvim' directory to the package path
package.path = config_dir .. "/?.lua;" .. package_path

-- Basic editor configuration
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.colorcolumn = "80"

-- Leader key
vim.g.mapleader = ','

-- enable x clipboard integration
vim.opt.clipboard = "unnamedplus"

-- Keybindings
require('keybindings').register()

Packages = require('packages')

Packages.install('https://github.com/neovim/nvim-lspconfig')
Packages.install('https://github.com/Mofiqul/dracula.nvim')

vim.cmd('colorscheme dracula')

require'lspconfig'.lua_ls.setup {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim'},
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
}
