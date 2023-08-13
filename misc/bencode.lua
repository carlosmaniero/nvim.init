local bencode = {}

local function encode_string(str)
  return string.format("%d:%s", string.len(str), str)
end

local function encode_key(key)
  return encode_string(key)
end

local function encode_integer(int)
  return string.format("i%de", int)
end

local function get_sorted_keys(data)
  local keys = {}

  for key, _ in pairs(data) do
    table.insert(keys, key)
  end

  table.sort(keys)
  return keys
end

local function encode_dictionary(data)
  local encoded = "d"

  for _, key in ipairs(get_sorted_keys(data)) do
    encoded = string.format("%s%s%s", encoded, encode_key(key), bencode.encode(data[key]))
  end

  return encoded .. "e"
end

local function encode_list(data)
  local encoded = "l"

  for _, value in pairs(data) do
    encoded = string.format("%s%s", encoded, bencode.encode(value))
  end

  return encoded .. "e"
end

local function is_array(data)
  -- For Lua dictionary and arrays are the same...
  local actual = 1

  for i, _ in pairs(data) do
    if i ~= actual then
      return false
    end
    actual = actual + 1
  end

  return true
end

local function encode_table(data)
  if is_array(data) then
    return encode_list(data)
  end
  return encode_dictionary(data)
end

local encoders = {
  string = encode_string,
  number = encode_integer,
  table = encode_table
}

function bencode.encode(value)
  return encoders[type(value)](value)
end

return bencode
