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

-- Configure plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Keybindings
require('keybindings').register()
