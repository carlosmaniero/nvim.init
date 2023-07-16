local symbol = {}
local position = require('misc.position')

function symbol.is(symbol_position, symbolName)
  local synId = vim.fn.synID(symbol_position.line, symbol_position.column, 0)
  return (
    vim.fn.synIDattr(synId, 'name') == symbolName or
    vim.fn.synIDattr(vim.fn.synIDtrans(synId), 'name') == symbolName
  )
end

function symbol.is_current(symbolName)
  return symbol.is(position.get_current(), symbolName)
end

return symbol
