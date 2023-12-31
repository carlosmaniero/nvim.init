local file = {}
local misc_prompt = require('misc.prompt')

function file.prompt()
  local files = vim.fn.glob("**")
  local lines = {}

  for line in string.gmatch(files, "([^\n]+)") do
    if vim.fn.isdirectory(line) == 0 then
      table.insert(lines, line)
    end
  end

  misc_prompt.create(
    lines,
    {
      on_selected = function (line)
        vim.api.nvim_command('e ' .. lines[line])
      end
    })
end

function test_file_prompt()
  file.prompt()
end


return file
