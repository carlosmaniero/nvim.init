local find_command = "find . -type f -not -path '*/\\.*' -print"

local file = {}
local misc_prompt = require('misc.prompt')

function file.prompt()
  local files = vim.fn.system(find_command)
  local lines = {}

  for line in string.gmatch(files, "([^\n]+)") do
    table.insert(lines, line)
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
