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

function position.get_selection_starts()
  return position.get_from_expr('v', 'v')
end

function position.compare(location1, location2)
  return (
    location1.line == location2.line and
    location1.column == location2.column
  )
end

return position
