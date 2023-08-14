local ripgrep = {}

local fs = require('misc.fs')

local ripgrep_window = nil

local function get_current_line_number()
  local line = vim.api.nvim_get_current_line()
  for token in line:gmatch('([^:]+)') do
    if tonumber(token) then
      return token
    end
    break
  end
end

function ripgrep.input()
  if ripgrep_window then
    vim.api.nvim_win_close(ripgrep_window, true)
  end
  local search = vim.fn.input('ripgrep: ')
  local previous_window = vim.api.nvim_get_current_win()

  vim.cmd('vsplit')

  ripgrep_window = vim.api.nvim_get_current_win()
  local ripgrep_width = math.floor(vim.api.nvim_win_get_width(ripgrep_window) * 0.60)
  vim.api.nvim_win_set_width(ripgrep_window, ripgrep_width)

  vim.cmd(string.format('terminal rg %s', search))

  vim.api.nvim_set_option_value('cursorline', true, { buf = 0 })

  vim.keymap.set('n', 'q', function()
    vim.cmd('q')
  end, { noremap = true, buffer = true })

  vim.keymap.set('n', '<Enter>', function()
    local line_number = get_current_line_number()

    while not line_number do
      vim.fn.feedkeys('k', 'x')
      local line = vim.api.nvim_get_current_line()
      if line == "" then
        return
      end
      line_number = get_current_line_number()
    end

    if line_number then
      local file = ""
      while file == "" do
        vim.fn.feedkeys('k', 'x')
        local line = vim.api.nvim_get_current_line()
        if fs.is_file(line) then
          file = line
        end
      end

      vim.api.nvim_set_current_win(previous_window)
      vim.cmd('e ' .. file)
      vim.cmd(line_number)
    end
  end, { noremap = true, buffer = true })
end

return ripgrep
