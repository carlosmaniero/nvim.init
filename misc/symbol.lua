local symbol = {}
local position = require('misc.position')

function symbol.is(symbol_position, symbol_name)
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

  while symbol.is_current(symbol_name) and not position.is_top(position.get_current()) do
    from = position.get_current()
    vim.fn.feedkeys(walk.prev, 'x')
  end

  position.go_to(current_position)

  while symbol.is_current(symbol_name) and not position.is_eof(position.get_current()) do
    to = position.get_current()
    vim.fn.feedkeys(walk.next, 'x')
  end

  position.go_to(current_position)

  return { from = from, to = to }
end

return symbol
