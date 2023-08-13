local function highlight_lines(buffer_number, lines)
  local line_number = 0
  for _, line_tokens in ipairs(lines) do
    local start_col = 0
    if type(line_tokens) ~= 'string' then
      for _, token in ipairs(line_tokens) do
        if type(token) == 'string' then
          start_col = start_col + string.len(token)
        else
          local end_col = start_col + string.len(token.value)
          vim.api.nvim_buf_add_highlight(buffer_number, -1, token.options.highlight_group, line_number, start_col,
            end_col)

          start_col = start_col + string.len(token.value)
        end
      end
    end
    line_number = line_number + 1
  end
end

local function prompt_set_buffer_lines(buffer_number, lines)
  local text_lines = {}

  for _, line_tokens in ipairs(lines) do
    local line = ""
    if type(line_tokens) == 'string' then
      line = line_tokens
    else
      for _, token in ipairs(line_tokens) do
        if type(token) == 'string' then
          line = line .. token
        else
          line = line .. token.value
        end
      end
    end
    table.insert(text_lines, line)
  end

  vim.api.nvim_buf_set_lines(buffer_number, 0, -1, false, text_lines)
  highlight_lines(buffer_number, lines)
end

local prompt = {}

function prompt.prompt_line_create(token, highlight_group)
  options = {}
  if highlight_group then
    options.highlight_group = highlight_group
  end
  return { value = token, options = options }
end

function prompt.create(lines, options)
  --[[
  --Create a prompt buffer.
  --
  --receives:
  --lines: a list of lines
  --options:
  --    - on_line_enter(line)
  --    - on_seleted(line)
  --    - current_line
  --
  --return:
  --The buffer number
  --
  --Line definition:
  --A line can be both a string of a list of tokens
  --
  --Token definition:
  --A token can be both a string or a table with the follow format:
  --
  --{value = "token string", options={}}
  --
  --Supported Options:
  --highlight_group: token's highlight group
  --]]
  options = options or {}

  local buffer_number = vim.api.nvim_create_buf(false, true)
  prompt_set_buffer_lines(buffer_number, lines)

  vim.api.nvim_buf_set_option(buffer_number, 'modifiable', false)

  local current_win = vim.api.nvim_get_current_win()

  local prompt_width = math.floor(vim.api.nvim_win_get_width(current_win) * 0.75)
  local prompt_height = math.floor(vim.api.nvim_win_get_height(current_win) * 0.5)

  local top = math.floor((vim.api.nvim_win_get_height(current_win) - prompt_height) / 2)
  local left = math.floor((vim.api.nvim_win_get_width(current_win) - prompt_width) / 2)

  vim.api.nvim_open_win(buffer_number, true, {
    relative = "win",
    width = prompt_width,
    height = prompt_height,
    row = top,
    col = left,
    border = 'single',
    style = 'minimal'
  })

  vim.api.nvim_set_option_value('cursorline', true, { buf = buffer_number })

  local state = {
    selected = false
  }

  if options.current_line then
    vim.api.nvim_win_set_cursor(0, { options.current_line, 0 })
  end

  if options.on_line_enter then
    local first_event = true
    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
      buffer = buffer_number,
      callback = function()
        if first_event then
          first_event = false
          return
        end
        local current_line = vim.api.nvim_win_get_cursor(0)[1]
        options.on_line_enter(current_line)
      end
    })
  end

  if options.on_selected then
    vim.keymap.set('n', '<Enter>', function()
      state.selected = true

      local current_line = vim.api.nvim_win_get_cursor(0)[1]
      vim.cmd("bd")
      options.on_selected(current_line)
    end, { buffer = buffer_number })
  end

  vim.api.nvim_create_autocmd({ "BufDelete", "WinClosed" }, {
    buffer = buffer_number,
    callback = function()
      if not state.selected and options.on_cancel then
        options.on_cancel()
      end
    end
  })

  -- Keybindings
  vim.keymap.set('n', 'q', function()
    vim.cmd("bd")
  end, { buffer = buffer_number })

  vim.keymap.set('n', '<C-c>', function()
    vim.cmd("bd")
  end, { buffer = buffer_number })

  return buffer_number
end

-- Simple test
function test_create()
  lines = {
    { "Line 1 ",                                     prompt.prompt_line_create("Token 2", "Boolean") },
    "My line 2",
    { prompt.prompt_line_create("Line 3", "Keyword") }
  }
  options = {
    current_line = 2,
    on_line_enter = function(current_line)
      print("Cursor position changed to line: " .. current_line)
    end,
    on_selected = function(current_line)
      print("The line selected was: " .. current_line)
    end,
    on_cancel = function()
      print("Cancelled")
    end
  }
  prompt.create(lines, options)
end

return prompt
