local suites = { 'tests.hello_test' }

local function print_error(error)
  print("\n" .. error .. "\n")
end

local function create_new_buffer()
  local new_buf = vim.api.nvim_create_buf(true, false)
  local current_buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_set_current_buf(new_buf)
  vim.api.nvim_buf_delete(current_buf, { force = true })
end

function RunSuite()
  local passed = true
  for _, suite_name in ipairs(suites) do
    print(string.format('- Running the test suite %s...\n', suite_name))
    local suite = require(suite_name)

    for name, test_fn in pairs(suite) do
      print(string.format('-> %s...', name))

      local ok, result = pcall(test_fn)

      if ok then
        print(' OK \n')
      else
        print_error(result)
        passed = false
      end
      create_new_buffer()
    end
  end

  print("\n")

  if passed then
    vim.cmd('quit!')
  else
    vim.cmd('cquit! 1')
  end
end
