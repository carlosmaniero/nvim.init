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

local function get_relative_path(file_path)
  return vim.fn.fnamemodify(file_path, ':~:.')
end

function buffer_indicator(buffer_number)
  if vim.api.nvim_get_current_buf() == buffer_number then
    return ">"
  else
    return " "
  end
end

function buffer_choose() 
  local buffer_options = string.format("Buffer list:\n%s\n", string.rep('-', 79))

  for _, buffer_number in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer_number) then
      buffer_options = string.format("%s%s %d\t%s\n", buffer_options, buffer_indicator(buffer_number), buffer_number, get_relative_path(vim.api.nvim_buf_get_name(buffer_number)));
    end
  end

  buffer_options = string.format("%sSelect a buffer: ", buffer_options)
  
  local ok, buffer_number = pcall(function() return vim.fn.input(buffer_options) end)

  if ok then
    if tonumber(buffer_number) ~= nil then
      vim.cmd(string.format("buffer %s", buffer_number))
    end
  end
end

-- enable x clipboard integration
vim.opt.clipboard = "unnamedplus"

vim.keymap.set('n', 'bn', function() vim.cmd("bn") end)
vim.keymap.set('n', 'bp', function() vim.cmd("bp") end)
vim.keymap.set('n', 'bd', function() vim.cmd("bd") end)
vim.keymap.set('n', 'bc', buffer_choose)

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
