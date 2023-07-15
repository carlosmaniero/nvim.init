local paredit = {}

local hi_namespace = vim.api.nvim_create_namespace("paredit")

local function is_token_a_string(line, column)
  local synId = vim.fn.synID(line, column, 0)
  return vim.fn.synIDattr(synId, 'name') == 'String' or vim.fn.synIDattr(vim.fn.synIDtrans(synId), 'name') == 'String'
end

function OpenParenLocation(parens_list)
  parens_list = parens_list or { { open = '(', close = ')' } }

  local current_buffer = 0
  local current_window = 0

  local cursor_line = vim.fn.line('.')
  local cursor_column = vim.fn.col('.')

  local window_height = vim.api.nvim_win_get_height(current_window)

  local range_start = math.max(cursor_line - window_height, 0)
  local range_end = cursor_line

  local in_range_lines = vim.api.nvim_buf_get_lines(current_buffer, range_start, range_end, true)
  local in_range_lines_len = #in_range_lines

  local parens_stack = {}
  for _, parens in ipairs(parens_list) do
    parens_stack[parens.close] = 1
  end

  local line_index_to_line_number = function(line_index)
    return cursor_line - (in_range_lines_len - line_index)
  end

  for line_index = in_range_lines_len, 1, -1 do
    local line = in_range_lines[line_index]
    local line_len = string.len(line)

    if line_index == in_range_lines_len then
      line_len = cursor_column
    end

    for column_index = line_len, 1, -1 do
      local current_character = line:sub(column_index, column_index)

      for _, parens in ipairs(parens_list) do
        if current_character == parens.open then
          local line_number = line_index_to_line_number(line_index)

          if not is_token_a_string(line_number, column_index) then
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

          if not is_token_a_string(line_number, column_index) then
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

  local cursor_line = vim.fn.line('.')
  local cursor_column = vim.fn.col('.')

  local window_height = vim.api.nvim_win_get_height(current_window)
  local total_of_lines = vim.api.nvim_buf_line_count(current_buffer)

  local range_start = cursor_line - 1
  local range_end = math.min(window_height + cursor_line, total_of_lines)

  local in_range_lines = vim.api.nvim_buf_get_lines(current_buffer, range_start, range_end, true)
  local in_range_lines_len = #in_range_lines

  local open_paren_count = 1

  local line_index_to_line_number = function(line_index)
    return cursor_line + line_index - 1
  end

  for line_index = 1, in_range_lines_len do
    local line = in_range_lines[line_index]
    local start_from = 1
    local line_len = string.len(line)

    if line_index == 1 then
      start_from = cursor_column
    end

    for column_index = start_from, line_len do
      local current_character = line:sub(column_index, column_index)

      if current_character == parens.close then
        local line_number = line_index_to_line_number(line_index)

        if not is_token_a_string(line_number, column_index) then
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

        if not is_token_a_string(line_number, column_index) then
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
  local parens_list = {
    { open = '(', close = ')' },
    { open = '[', close = ']' },
    { open = '{', close = '}' }
  }

  local open = OpenParenLocation(parens_list)

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

local function in_range_selection(from, to)
  local cursor_line = vim.fn.line('.')

  if cursor_line ~= from.line then
    vim.fn.feedkeys(string.format('%dk', cursor_line - from.line))
  end

  vim.fn.feedkeys(string.format('%d|', from.column))

  vim.fn.feedkeys('v')

  if to.line ~= from.line then
    vim.fn.feedkeys(string.format('%dj', to.line - from.line))
  end

  vim.fn.feedkeys(string.format('%d|', to.column))
end

local function go_to_next_char()
  local cursor_line = vim.fn.line('.')
  local cursor_column = vim.fn.col('.')

  local line = vim.api.nvim_buf_get_lines(0, cursor_line - 1, cursor_line, true)[1]
  if cursor_column >= string.len(line) then
    vim.fn.feedkeys('j0')
  else
    vim.fn.feedkeys('l')
  end
end

local function go_to_prev_char()
  local cursor_column = vim.fn.col('.')

  if cursor_column <= 1 then
    vim.fn.feedkeys('k$')
    -- In visual mode the \n counts as a char so its needed to back one more
    if vim.fn.mode() == 'v' then
      vim.fn.feedkeys('h')
    end
  else
    vim.fn.feedkeys('h')
  end
end

local function get_location(expr)
  local pos = vim.fn.getpos(expr)
  return { line = pos[2], column = pos[3] }
end

local function compare_location(location1, location2)
  return (
    location1.line == location2.line and
    location1.column == location2.column
  )
end


local function get_current_selection()
  return {
    from = get_location('v'),
    to = get_location('.')
  }
end

local surroundings_stack = {}

local function compare_selection(from, to)
  local selection = get_current_selection()
  return (
    compare_location(selection.from, from) and compare_location(selection.to, to))
end

function paredit.previous_selection()
  if #surroundings_stack == 1 then
    return
  end
  table.remove(surroundings_stack, #surroundings_stack)
  local surroundings = surroundings_stack[#surroundings_stack]

  if surroundings then
    vim.fn.feedkeys('v')
    in_range_selection(
      surroundings.open, surroundings.close)
  end
end

function paredit.next_selection()
  local surroundings = GetSurroundings()
  if surroundings then
    if compare_selection(surroundings.open, surroundings.close) then
      go_to_next_char()

      vim.schedule(function()
        surroundings = GetSurroundings()

        if surroundings then
          table.insert(surroundings_stack, surroundings)

          vim.fn.feedkeys('v')
          in_range_selection(
            surroundings.open, surroundings.close)
        else
          go_to_prev_char()
        end
      end)
    else
      surroundings_stack = { surroundings }
      vim.fn.feedkeys('v')
      in_range_selection(
        surroundings.open, surroundings.close)
    end
  end
end

return paredit
