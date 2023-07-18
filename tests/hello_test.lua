local asserts = require('tests.asserts')

local tests = {}

function tests.basic_test_just_to_test_the_test_suite()
  vim.fn.feedkeys('iHello, World', 'itx')
  vim.fn.feedkeys('\\<Esc>', 'x')
  asserts.line_equal(1, "Hello, World")
end

function tests.another_basic_test_just_to_test_the_test_suite()
  vim.fn.feedkeys('iBye', 'itx')
  vim.fn.feedkeys('\\<Esc>', 'x')
  asserts.line_equal(1, "Bye")
end

return tests
