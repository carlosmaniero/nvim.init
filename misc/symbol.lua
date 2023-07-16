local symbol = {}
local position = require('misc.position')

local function get_char(symbol_position)
  local line = vim.api.nvim_get_current_line()
  local char = line:sub(symbol_position.column, symbol_position.column)
  return char
end

function symbol.get_name(symbol_position)
  local synId = vim.fn.synID(symbol_position.line, symbol_position.column, 0)
  return vim.fn.synIDattr(vim.fn.synIDtrans(synId), 'name')
end

function symbol.is(symbol_position, symbol_name)
  if symbol_name ~= 'String' then
    if get_char(symbol_position) == ' ' or get_char(symbol_position) == '' then
      return false
    end
  end
  local synId = vim.fn.synID(symbol_position.line, symbol_position.column, 0)
  return (
    vim.fn.synIDattr(synId, 'name') == symbol_name or
    vim.fn.synIDattr(vim.fn.synIDtrans(synId), 'name') == symbol_name
  )
end

function symbol.is_current(symbol_name)
  return symbol.is(position.get_current(), symbol_name)
end

function symbol.get_current_symbol_position(symbol_name)
  local current_position = position.get_current()
  local from = current_position
  local to = current_position
  local walk = { prev = 'h', next = 'l' }

  if symbol_name == 'String' then
    walk = { prev = 'b', next = 'w' }
  end

  while symbol.is_current(symbol_name) do
    from = position.get_current()

    if from.column == 1 then
      -- Strings may be multiline
      if symbol_name == 'String' then
        if position.is_top(from) then
          break
        end
      else
        break
      end
    end

    vim.fn.feedkeys(walk.prev, 'x')
  end

  position.go_to(current_position)

  while symbol.is_current(symbol_name) do
    to = position.get_current()

    if position.is_eol(to) then
      if symbol_name == 'String' then
        if position.is_eof(to) then
          break
        end
      else
        break
      end
    end

    vim.fn.feedkeys(walk.next, 'x')
  end

  position.go_to(current_position)

  return { from = from, to = to }
end

function GetPostion()
  return symbol.get_current_symbol_position(symbol.get_name(position.get_current()))
end

function GetName()
  return symbol.get_name(position.get_current())
end

return symbol
