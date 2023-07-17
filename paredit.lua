local paredit = {
  raisable_symbols = { 'String', 'Number', 'Character', 'Boolean', 'Keyword' }
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

local function get_char(symbol_position)
  local line = vim.api.nvim_get_current_line()
  local char = line:sub(symbol_position.column, symbol_position.column)
  return char
end

local function is_char_empty(symbol_position)
  local char = get_char(symbol_position)
  return char == ' ' or char == ''
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

          if not symbol.is({ line = line_number, column = column_index }, 'String') then
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

          if not symbol.is({ line = line_number, column = column_index }, 'String') then
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

        if not symbol.is({ line = line_number, column = column_index }, 'String') then
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

        if not symbol.is({ line = line_number, column = column_index }, 'String') then
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
  vim.fn.feedkeys(' ', 'x')
end

local function go_to_prev_char()
  vim.fn.feedkeys('\b', 'x')
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

local function is_current_open_paren()
  for _, paren in ipairs(supported_parens_list) do
    if get_char(position.get_current()) == paren.open then
      return true
    end
  end
  return false
end

local function is_current_close_paren()
  for _, paren in ipairs(supported_parens_list) do
    if get_char(position.get_current()) == paren.close then
      return true
    end
  end
  return false
end

function paredit.swallow()
  local surroundings = GetSurroundings()

  if surroundings then
    position.go_to(surroundings.close)

    go_to_next_char()

    while is_char_empty(position.get_current()) and not position.is_eof(position.get_current()) do
      go_to_next_char()
    end

    local swallow_until = surroundings.close

    if is_current_open_paren() then
      local swallow_surroundings = GetSurroundings()
      if swallow_surroundings then
        swallow_until = swallow_surroundings.close
      end
    else
      if is_current_close_paren() then
        paredit.swallow()
        position.go_to(surroundings.close)
        paredit.swallow()
        return
      end
      local current_symbol_name = symbol.get_name(position.get_current())
      swallow_until = symbol.get_current_symbol_position(current_symbol_name).to
    end

    position.go_to(surroundings.close)

    vim.fn.feedkeys('vyx', 'x')

    if swallow_until.line == surroundings.close.line then
      swallow_until.column = swallow_until.column - 1
    end

    position.go_to(swallow_until)

    vim.fn.feedkeys('p', 'x')
  end
end

function paredit.spew()
  local surroundings = GetSurroundings()

  if surroundings then
    position.go_to(surroundings.close)

    go_to_prev_char()

    while is_char_empty(position.get_current()) and not position.is_top(position.get_current()) do
      go_to_prev_char()
    end

    local swallow_until = surroundings.close

    if is_current_close_paren() then
      local swallow_surroundings = GetSurroundings()
      if swallow_surroundings then
        swallow_until = swallow_surroundings.open
      end
    else
      local current_symbol_name = symbol.get_name(position.get_current())
      swallow_until = symbol.get_current_symbol_position(current_symbol_name).from
    end

    if position.compare(surroundings.close, swallow_until) then
      return
    end

    position.go_to(surroundings.close)

    vim.fn.feedkeys('vyx', 'x')

    position.go_to(swallow_until)

    go_to_prev_char()

    while is_char_empty(position.get_current()) and not position.is_top(position.get_current()) do
      go_to_prev_char()
    end

    vim.fn.feedkeys('p', 'x')
  end
end

function paredit.raise()
  local count = math.max(tonumber(vim.v.count) or 1, 1)

  for _ = 1, count do
    local should_raise_parent = true
    local current_symbol_location = nil

    if vim.fn.mode() ~= 'v' then
      for _, sym in ipairs(paredit.raisable_symbols) do
        if symbol.is_current(sym) then
          should_raise_parent = false
          current_symbol_location = symbol.get_current_symbol_position(sym)
          break
        end
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
        if current_symbol_location then
          selection.range(current_symbol_location.from, current_symbol_location.to)
        else
          vim.fn.feedkeys('viw')
        end
      end

      vim.fn.feedkeys('ygv', 'x')
      local parent_selection = paredit.next_selection()

      if parent_selection then
        vim.fn.feedkeys('p', 'x')
      end
    end
  end
end

function paredit.on_insert_char(char)
  if char == '(' then
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes(')<Left>', true, false, true), 'it')
  end
  if char == '[' then
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes(']<Left>', true, false, true), 'it')
  end
  if char == '{' then
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes('}<Left>', true, false, true), 'it')
  end
end

-- Return true if it should continue with the deletion
function paredit.should_remove_block()
  local current_position = position.get_current()
  current_position.column = current_position.column - 1

  local previous_char = get_char(current_position)

  if previous_char then
    for _, paren in ipairs(supported_parens_list) do
      if previous_char == paren.open or previous_char == paren.close then
        return true
      end
    end
  end
  return false
end

-- Return true if a block were removed
function paredit.remove_block()
  local current_position = position.get_current()
  local current_char = get_char(current_position)

  if current_char then
    for _, paren in ipairs(supported_parens_list) do
      if current_char == paren.open or current_char == paren.close then
        -- Changes connot be committed on keymaps
        -- so then the changes are scheduled
        vim.schedule(function()
          if vim.fn.mode() ~= 'v' then
            vim.fn.feedkeys('v', 'x')
          end
          paredit.next_selection()
          vim.fn.feedkeys('x', 'x')
        end)

        return true
      end
    end
  end
  return false
end

return paredit
