local paredit = {
  raise_parent_on_first_word = true
}

local position = require('misc.position')
local selection = require('misc.selection')
local symbol = require('misc.symbol')

local hi_namespace = vim.api.nvim_create_namespace("paredit")

local supported_parens_list = {
  { open = '(', close = ')' },
  { open = '[', close = ']' },
  { open = '{', close = '}' }
}

local function get_current_char()
  local cursor = position.get_current()
  local line = vim.api.nvim_get_current_line()
  local char = line:sub(cursor.column, cursor.column)
  return char
end

function OpenParenLocation(parens_list)
  parens_list = parens_list or { { open = '(', close = ')' } }

  local current_buffer = 0
  local current_window = 0

  local cursor_position = position.get_current()

  local window_height = vim.api.nvim_win_get_height(current_window)

  local range_start = math.max(cursor_position.line - window_height, 0)
  local range_end = cursor_position.line

  local in_range_lines = vim.api.nvim_buf_get_lines(current_buffer, range_start, range_end, true)
  local in_range_lines_len = #in_range_lines

  local parens_stack = {}
  for _, parens in ipairs(parens_list) do
    parens_stack[parens.close] = 1
  end

  local line_index_to_line_number = function(line_index)
    return cursor_position.line - (in_range_lines_len - line_index)
  end

  for line_index = in_range_lines_len, 1, -1 do
    local line = in_range_lines[line_index]
    local line_len = string.len(line)

    if line_index == in_range_lines_len then
      line_len = cursor_position.column
    end

    for column_index = line_len, 1, -1 do
      local current_character = line:sub(column_index, column_index)

      for _, parens in ipairs(parens_list) do
        if current_character == parens.open then
          local line_number = line_index_to_line_number(line_index)

          if not symbol.is({line = line_number, column = column_index}, 'String') then
            parens_stack[parens.close] = parens_stack[parens.close] - 1
            if parens_stack[parens.close] == 0 then
              return {
                line = line_number,
                column = column_index,
                parens = parens
              }
            end
          end
        end

        if current_character == parens.close then
          local line_number = line_index_to_line_number(line_index)

          if not symbol.is({line = line_number, column = column_index}, 'String') then
            -- That's ok if the current character is a close paren
            if line_index ~= in_range_lines_len or column_index ~= line_len then
              parens_stack[parens.close] = parens_stack[parens.close] + 1
            end
          end
        end
      end
    end
  end
  return nil
end

function CloseParenLocation(parens)
  parens = parens or { open = '(', close = ')' }

  local current_buffer = 0
  local current_window = 0

  local cursor_position = position.get_current()

  local window_height = vim.api.nvim_win_get_height(current_window)
  local total_of_lines = vim.api.nvim_buf_line_count(current_buffer)

  local range_start = cursor_position.line - 1
  local range_end = math.min(window_height + cursor_position.line, total_of_lines)

  local in_range_lines = vim.api.nvim_buf_get_lines(current_buffer, range_start, range_end, true)
  local in_range_lines_len = #in_range_lines

  local open_paren_count = 1

  local line_index_to_line_number = function(line_index)
    return cursor_position.line + line_index - 1
  end

  for line_index = 1, in_range_lines_len do
    local line = in_range_lines[line_index]
    local start_from = 1
    local line_len = string.len(line)

    if line_index == 1 then
      start_from = cursor_position.column
    end

    for column_index = start_from, line_len do
      local current_character = line:sub(column_index, column_index)

      if current_character == parens.close then
        local line_number = line_index_to_line_number(line_index)

        if not symbol.is({line = line_number, column = column_index}, 'String') then
          open_paren_count = open_paren_count - 1
          if open_paren_count == 0 then
            return {
              line = line_number,
              column = column_index
            }
          end
        end
      end

      if current_character == parens.open then
        local line_number = line_index_to_line_number(line_index)

        if not symbol.is({line = line_number, column = column_index}, 'String') then
          -- That's ok if the current character is a open paren
          if line_index > 1 or column_index ~= start_from then
            open_paren_count = open_paren_count + 1
          end
        end
      end
    end
  end
  return nil
end

function GetSurroundings()
  local open = OpenParenLocation(supported_parens_list)

  if open then
    local close = CloseParenLocation(open.parens)

    if close then
      return { open = open, close = close }
    end
  end
  return nil
end

function paredit.highlight_surroundings()
  vim.api.nvim_buf_clear_namespace(0, hi_namespace, 0, -1)

  local surroundings = GetSurroundings()

  if surroundings then
    vim.api.nvim_buf_add_highlight(0, hi_namespace, 'MatchParen',
      surroundings.open.line - 1, surroundings.open.column - 1, surroundings.open.column)
    vim.api.nvim_buf_add_highlight(0, hi_namespace, 'MatchParen',
      surroundings.close.line - 1, surroundings.close.column - 1, surroundings.close.column)
  end
end

local function go_to_next_char()
  local cursor_position = position.get_current()

  local line = vim.api.nvim_buf_get_lines(0, cursor_position.line - 1, cursor_position.line, true)[1]
  if cursor_position.column >= string.len(line) then
    vim.fn.feedkeys('j0', 'x')
  else
    vim.fn.feedkeys('l', 'x')
  end
end

local function go_to_prev_char()
  if position.get_current().column <= 1 then
    vim.fn.feedkeys('k$', 'x')
    -- In visual mode the \n counts as a char so its needed to back one more
    if vim.fn.mode() == 'v' then
      vim.fn.feedkeys('h', 'x')
    end
  else
    vim.fn.feedkeys('h', 'x')
  end
end

local function select_surroundings(surroundings)
  selection.range(surroundings.open, surroundings.close)
end

local surroundings_stack = {}

function paredit.previous_selection()
  if #surroundings_stack == 1 then
    return
  end
  table.remove(surroundings_stack, #surroundings_stack)
  local surroundings = surroundings_stack[#surroundings_stack]

  if surroundings then
    select_surroundings(surroundings)
  end
end

function paredit.next_selection()
  local surroundings = GetSurroundings()
  if surroundings then
    if selection.compare(surroundings.open, surroundings.close) then
      go_to_next_char()

      local new_surroundings = GetSurroundings()

      if new_surroundings then
        table.insert(surroundings_stack, new_surroundings)

        select_surroundings(new_surroundings)

        return {
          changed = true,
          surroundings = new_surroundings
        }
      else
        go_to_prev_char()

        return {
          changed = false,
          surroundings = surroundings
        }
      end
    else
      surroundings_stack = { surroundings }
      select_surroundings(surroundings)

      return {
        initial = true,
        surroundings = surroundings
      }
    end

    options.selected_callback({
      initial = true,
    })
  end
end

function paredit.raise()
  local count = math.max(tonumber(vim.v.count) or 1, 1)

  for _ = 1, count do
    local should_raise_parent = false

    for _, paren in ipairs(supported_parens_list) do
      if get_current_char() == paren.open then
        should_raise_parent = true
        break
      end
    end

    if should_raise_parent then
      local initial_selection = paredit.next_selection()

      if initial_selection then
        -- Copy and reselect the text
        vim.fn.feedkeys('ygv', 'x')
        local parent_selection = paredit.next_selection()

        if parent_selection and parent_selection.changed then
          vim.fn.feedkeys('p', 'x')
        end
      end
    else
      if vim.fn.mode() ~= 'v' then
        vim.fn.feedkeys('viw')
      end

      vim.fn.feedkeys('ygv', 'x')
      local parent_selection = paredit.next_selection()

      if parent_selection then
        vim.fn.feedkeys('p', 'x')
      end
    end
  end
end

return paredit
