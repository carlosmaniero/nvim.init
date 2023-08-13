local repl = {}

local bencode = require('misc.bencode')

local client = vim.uv.new_tcp()
local callbacks = {}

local main_session = nil
local debug_index = 0

function repl.write_callback(data)
  debug_index = debug_index + 1
  local file = io.open(string.format('/tmp/output-%d.txt', debug_index), 'w')
  if file then
    if type(data) ~= "string" then
      data = vim.inspect(data)
    end
    file:write(data)
    io.close(file)
  end
end

function repl.send(msg, callback)
  -- TODO: The clone is not safe this is something the send may need to control
  -- If there is something beeing cloned the previous one must wait

  callbacks[main_session] = callback
  msg.session = main_session
  client:write(bencode.encode(msg))
end

local function read_forever(connection_callback)
  local content = ""
  client:read_start(function(err, chunk)
    assert(not err, err)
    content = content .. chunk

    while true do
      if content == "" then
        break
      end
      local decoded = bencode.decode(content)

      if not decoded then
        break
      end

      if main_session == nil then
        main_session = decoded.value["new-session"]

        if not main_session then
          connection_callback("Error start repl session.")
        else
          connection_callback()
        end
      else
        if callbacks[decoded.value.session] then
          vim.schedule(function()
            callbacks[decoded.value.session](decoded.value)
          end)
        end
      end

      content = decoded.rest
    end
  end)
end

function repl.connect(host, port, callback)
  if port == nil then
    port = host
    host = "127.0.0.1"
  end

  callback = callback or function(err)
    if err then
      print(err)
    end
  end

  local async_callback = function(err)
    vim.schedule(function()
      callback(err)
    end)
  end

  client:connect(host, port, function(err)
    if err then
      async_callback(err)
      return
    end

    client:write(bencode.encode({ op = "clone", session = main_session }))
    read_forever(async_callback)
  end)
end

function repl.eval(code, ns, callback)
  repl.send({ op = "eval", ns = ns, code = code }, function(result)
    callback(result)
  end)
end

function repl.require(namespace, callback)
  client:write(bencode.encode({
    op = "eval",
    session = main_session,
    code = string.format("(require '%s)", namespace)
  }))

  callbacks[main_session] = callback
end

function repl.is_connected()
  return main_session ~= nil
end

return repl
