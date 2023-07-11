local hi_namespace = vim.api.nvim_create_namespace("paredit")

local function is_token_a_string(line, column)
  local synId = vim.fn.synID(line, column, 0)
  return vim.fn.synIDattr(synId, 'name') == 'String' or vim.fn.synIDattr(vim.fn.synIDtrans(synId), 'name') == 'String'
end

function OpenParenLocation()
  local current_buffer = 0
  local current_window = 0

  local cursor_line = vim.fn.line('.')
  local cursor_column = vim.fn.col('.')

  local window_height = vim.api.nvim_win_get_height(current_window)

  local range_start = math.max(cursor_line - window_height, 0)
  local range_end = cursor_line

  local in_range_lines = vim.api.nvim_buf_get_lines(current_buffer, range_start, range_end, true)
  local in_range_lines_len = #in_range_lines

  local close_paren_count = 1

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

      if current_character == '(' then
        local line_number = line_index_to_line_number(line_index)

        if not is_token_a_string(line_number, column_index) then
          close_paren_count = close_paren_count - 1
          if close_paren_count == 0 then
            return {
              line = line_number,
              column = column_index
            }
          end
        end
      end

      if current_character == ')' then
        local line_number = line_index_to_line_number(line_index)

        if not is_token_a_string(line_number, column_index) then
          close_paren_count = close_paren_count + 1
        end
      end
    end
  end
  return nil
end

function HI_open_paren()
  vim.api.nvim_buf_clear_namespace(0, hi_namespace, 0, -1)

  local open_paren = OpenParenLocation()

  if open_paren then
    vim.api.nvim_buf_add_highlight(0, hi_namespace, 'MatchParen', open_paren.line - 1, open_paren.column - 1, open_paren.column)
  end
end

vim.api.nvim_create_autocmd({ "CursorMoved" }, {
  callback = function()
    HI_open_paren()
  end
})
