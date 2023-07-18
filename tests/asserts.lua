local asserts = {}

local function make_error(error_message, traceback)
  local separator = '--------------------------------------------------'

  return string.format('\n%s\n\n%s\n\n%s\n%s\n\n', separator, error_message, separator, traceback)
end

function asserts.string_equals(actual, expected)
  if actual ~= expected then
    error(make_error(string.format('Expected: "%s"\nActual: "%s"', expected, actual), debug.traceback()))
  end
end

function asserts.line_equal(line_number, expected)
  local line = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, true)[1]

  if line ~= expected then
    error(make_error(
      string.format('Expected line #%d: "%s"\nActual line #%d: "%s"',
        line_number, expected, line_number, line
      ),
      debug.traceback())
    )
  end
end

return asserts
