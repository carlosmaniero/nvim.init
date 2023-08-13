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

local function decode_string(str)
  for size in str:gmatch('%d+') do
    local isize = tonumber(size)
    local size_len = #size
    local key_begining = size_len + 2

    return {
      value = str:sub(key_begining, key_begining + isize - 1),
      rest = str:sub(key_begining + isize, #str)
    }
  end
end

local function decode_key(str)
  return decode_string(str)
end

local function decode_dict(str, dict)
  dict = dict or {}

  if str == "" then
    return nil
  end

  if str:sub(1, 1) == "e" then
    return {
      value = dict,
      rest = str:sub(2, #str)
    }
  end

  local key = decode_key(str)
  local value = bencode._decoder(key.rest)

  if not value then
    return nil
  end

  dict[key.value] = value.value

  return decode_dict(value.rest, dict)
end

local function decode_list(str, list)
  list = list or {}

  if str:sub(1, 1) == "e" then
    return {
      value = list,
      rest = str:sub(2, #str)
    }
  end

  local value = bencode._decoder(str)
  table.insert(list, value.value)

  return decode_list(value.rest, list)
end

local function decode_integer(str)
  local str_integer = ""
  for i = 1, #str do
    local char = str:sub(i, i)
    if char == "e" then
      return {
        value = tonumber(str_integer),
        rest = str:sub(i + 1, #str)
      }
    end
    str_integer = str_integer .. char
  end
end

local decoders = {
  d = decode_dict,
  i = decode_integer,
  l = decode_list
}

function bencode._decoder(str)
  local kind = str:sub(1, 1)
  local value = str:sub(2, #str)

  if tonumber(kind) ~= nil then
    return decode_string(str)
  end

  local decoder = decoders[kind]

  if decoder == nil then
    return nil
  end

  return decoder(value)
end

function bencode.decode(str)
  return bencode._decoder(str)
end

return bencode
