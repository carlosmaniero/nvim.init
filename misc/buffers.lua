local buffers = {};

local misc_fs = require('misc.fs')
local prompt = require('misc.prompt')

function buffers.buffer_choose()
  local lines = {}
  local buffers = {}
  local current_line = 0
  local current_line_found = false

  local current_window = vim.api.nvim_get_current_win()
  local current_buffer = vim.api.nvim_get_current_buf()

  for _, buffer_number in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer_number) then
      if not current_line_found then
        current_line = current_line + 1
        current_line_found = buffer_number == current_buffer
      end

      local buffer_option = string.format("%4d %s", buffer_number, misc_fs.get_relative_path(vim.api.nvim_buf_get_name(buffer_number)));

      table.insert(buffers, buffer_number)
      table.insert(lines, buffer_option)
    end
  end

  prompt.create(lines, {
    current_line = current_line,
    on_line_enter = function(line)
      vim.api.nvim_win_set_buf(current_window, buffers[line])
    end,
    on_selected = function(line)
      vim.api.nvim_win_set_buf(current_window, buffers[line])
    end,
    on_cancel = function(line)
      vim.api.nvim_win_set_buf(current_window, current_buffer)
    end
  })
end

function test_buffer_select()
  buffers.buffer_select()
end

return buffers
