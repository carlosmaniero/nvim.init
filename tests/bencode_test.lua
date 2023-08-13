local asserts = require('tests.asserts')

local tests = {}

function tests.encodes_a_simple_table_test()
  local bencode = require('misc.bencode')
  asserts.string_equals(bencode.encode({ foo = 42, bar = 13 }), "d3:bari13e3:fooi42ee")
  asserts.string_equals(bencode.encode({ foo = "vegan bar" }), "d3:foo9:vegan bare")
  asserts.string_equals(bencode.encode({ foo = { bar = 42 } }), "d3:food3:bari42eee")
  asserts.string_equals(bencode.encode({ foo = { 1, "bar" } }), "d3:fooli1e3:baree")
end

function tests.decoding_test()
  local bencode = require('misc.bencode')
  local dicts = {
    {
      foo = 42,
      bar = 13
    },
    { foo = "vegan\nbar" },
    { foo = { bar = 42 } },
    { foo = { 1, "bar" } }
  }

  for _, value in ipairs(dicts) do
    asserts.string_equals(
      vim.inspect(value),
      vim.inspect(bencode.decode(bencode.encode(value)).value))
  end
end

function tests.decoding_error()
  local bencode = require('misc.bencode')
  asserts.is_nil(bencode.decode("d3:bari13e3:fooi42e"))
  asserts.is_nil(bencode.decode("z"))
end


return tests
