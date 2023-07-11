local hi_namespace = vim.api.nvim_create_namespace("paredit")

local function is_token_a_string(line, column)
  local synId = vim.fn.synID(line, column, 0)
  return vim.fn.synIDattr(synId, 'name') == 'String' or vim.fn.synIDattr(vim.fn.synIDtrans(synId), 'name') == 'String'
end

function OpenParenLocation()
  local current_buffer = 0
  local line_number = vim.fn.line('.')
  local cursor_column = vim.fn.col('.')
  local line = vim.api.nvim_buf_get_lines(current_buffer, line_number - 1, line_number, false)[1] or ""
  local found = false
  local close_paren_count = 1
  local start_line = math.max(line_number - vim.api.nvim_win_get_height(0), 0)

  repeat
    local current_character = line:sub(cursor_column, cursor_column)

    if current_character == '(' then
      if not is_token_a_string(line_number, cursor_column) then
        close_paren_count = close_paren_count - 1
        if close_paren_count == 0 then
          found = true
        end
      end
    end

    if not found then
      if current_character == ')' then
        if not is_token_a_string(line_number, cursor_column) then
          close_paren_count = close_paren_count + 1
        end
      end
      cursor_column = cursor_column - 1

      if cursor_column == 0 then
        line_number = line_number - 1
        if line_number < start_line then
          return nil
        end
        line = vim.api.nvim_buf_get_lines(current_buffer, line_number - 1, line_number, false)[1] or ""
        cursor_column = string.len(line) + 1
      end
    end
  until found

  return { line = line_number, column = cursor_column }
end

function HI_open_paren()
  vim.api.nvim_buf_clear_namespace(0, hi_namespace, 0, -1)

  local open_paren = OpenParenLocation()

  if open_paren then
    -- vim.fn.matchaddpos('MatchParen', {{open_paren.line, open_paren.column}})
    vim.api.nvim_buf_add_highlight(0, hi_namespace, 'MatchParen', open_paren.line - 1, open_paren.column - 1,
      open_paren.column)
  end
end

vim.api.nvim_create_autocmd({ "CursorMoved" }, {
  callback = function()
    HI_open_paren()
  end
})
