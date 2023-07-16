local selection = {}
local position = require('misc.position')

function selection.range(from, to)
  if vim.fn.mode() == 'v' then
    vim.fn.feedkeys('v')
  end

  local cursor_position = position.get_current()

  if cursor_position.line ~= from.line then
    vim.fn.feedkeys(string.format('%dk', cursor_position.line - from.line))
  end

  vim.fn.feedkeys(string.format('%d|', from.column))

  vim.fn.feedkeys('v')

  if to.line ~= from.line then
    vim.fn.feedkeys(string.format('%dj', to.line - from.line))
  end

  vim.fn.feedkeys(string.format('%d|', to.column))

  -- Cleans typeahead
  vim.fn.feedkeys('', 'x')
end

function selection.get_current()
  return {
    from = position.get_selection_starts(),
    to = position.get_current()
  }
end

function selection.compare(from, to)
  local current_selection = selection.get_current()
  return (
    position.compare(current_selection.from, from) and position.compare(current_selection.to, to))
end

return selection
