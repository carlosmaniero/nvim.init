local uuid = {}

function uuid.random()
  local template = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  return "" .. string.gsub(template, "x", function()
    local v = math.random(0, 0xf)
    return string.format("%x", v)
  end)
end

return uuid
