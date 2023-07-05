local buffers = {};

local misc_fs = require('misc.fs')

function buffers.buffer_indicator(buffer_number)
  if vim.api.nvim_get_current_buf() == buffer_number then
    return ">"
  else
    return " "
  end
end

function buffers.buffer_choose() 
  local buffer_options = string.format("Buffer list:\n%s\n", string.rep('-', 79))

  for _, buffer_number in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer_number) then
      buffer_options = string.format("%s%s %d\t%s\n", buffer_options, buffers.buffer_indicator(buffer_number), buffer_number, misc_fs.get_relative_path(vim.api.nvim_buf_get_name(buffer_number)));
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

return buffers;
