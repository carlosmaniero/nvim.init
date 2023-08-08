-- Get the current package path
local package_path = package.path

local config_dir = vim.fn.stdpath('config')

-- Add the path to the 'nvim' directory to the package path
package.path = config_dir .. "/?.lua;" .. package_path

-- matchparen may cause issues with clojure
vim.g.loaded_matchparen = 1

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

Packages = require('packages')

Packages.install('https://github.com/neovim/nvim-lspconfig')
Packages.install('https://github.com/Mofiqul/dracula.nvim')
Packages.install('https://github.com/nvim-lua/plenary.nvim')
Packages.install('https://github.com/nvim-telescope/telescope.nvim')

vim.cmd('colorscheme dracula')

require('diagnostic').setup()
require('lsp').setup()

-- Keybindings
require('keybindings').register()

require('languages.clojure')
