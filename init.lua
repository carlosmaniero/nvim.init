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
