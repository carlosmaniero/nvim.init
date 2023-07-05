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

-- Keybindings
vim.g.mapleader = ','

local misc_buffers = require('misc.buffers')

-- enable x clipboard integration
vim.opt.clipboard = "unnamedplus"

vim.keymap.set('n', 'bn', function() vim.cmd("bn") end)
vim.keymap.set('n', 'bp', function() vim.cmd("bp") end)
vim.keymap.set('n', 'bd', function() vim.cmd("bd") end)
vim.keymap.set('n', 'bc', misc_buffers.buffer_choose)

-- Configure plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)
