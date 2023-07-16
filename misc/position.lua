local position = {}

function position.get_from_expr(line_expr, column_expr)
  return {
    line = vim.fn.line(line_expr),
    column = vim.fn.col(column_expr)
  }
end

function position.get_current()
  return position.get_from_expr('.', '.')
end

function position.is_top(location)
  return location.line == 1 and location.column == 1
end

function position.is_eof(location)
  local eof = position.get_from_expr('$', '$')
  return location.line == eof.line and location.column == eof.column - 1
end

function position.is_eol(location)
  local eof = position.get_from_expr('.', '$')
  return location.line == eof.line and location.column >= eof.column - 1
end

function position.get_selection_starts()
  return position.get_from_expr('v', 'v')
end

function position.compare(location1, location2)
  return (
    location1.line == location2.line and
    location1.column == location2.column
  )
end

function position.go_to(location)
  local cursor_position = position.get_current()

  if cursor_position.line < location.line then
    vim.fn.feedkeys(string.format('%dj', location.line - cursor_position.line))
  else
    if cursor_position.line > location.line then
      vim.fn.feedkeys(string.format('%dk', cursor_position.line - location.line))
    end
  end

  vim.fn.feedkeys(string.format('%d|', location.column), 'x')
end

return position
