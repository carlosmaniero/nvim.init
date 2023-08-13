local repl_ui = {}
local repl = require('languages.clojure.repl')

function repl_ui.connect()
  local host = vim.fn.input("repl host: ", "127.0.0.1")
  local port = tonumber(vim.fn.input("repl port: "))

  if port == nil then
    print("\nrepl port must be an integer")
  end

  repl.connect(host, port, function(err)
    if err then
      --print(err)
      return
    end

    print("Repl connected")
  end)
end

function repl_ui.autoconnect()
  local repl_file = vim.fn.getcwd() .. '/' .. '.nrepl-port'
  local file = io.open(repl_file, "r")

  if file == nil then
    print("Could not autoconnect provide the host and port")
    repl_ui.connect()
    return
  end

  local port = tonumber(file:read("*a"))
  file:close()

  print("Connecting to repl...")

  repl.connect("127.0.0.1", port, function(err)
    if err then
      print("Could not autoconnect provide the host and port")
      repl_ui.connect()
      return
    end

    print("Repl connected")
  end)
end

local function get_namespace()
  -- Try to find the namespace name on the first 200 lines
  local lines = vim.api.nvim_buf_get_lines(0, 0, 200, false)

  for _, line in ipairs(lines) do
    if line:find("(ns ", 1, true) == 1 then
      return line:gsub("[(]ns ", "")
    end
  end

  print("could not identify the current namespace")
end

local function make_eval_callback(prompt_header)
  local lines = {}
  for s in prompt_header:gmatch("[^\r\n]+") do
    table.insert(lines, s)
  end

  local prompt = require('misc.prompt')
  local prompt_buffer = prompt.create(lines, {})

  return function(response)
    local response_data = ""

    local function append_response(text)
      if response_data ~= "" then
        response_data = response_data .. "\n"
      end
      response_data = response_data .. text
    end

    if response.err then
      append_response(response.err)
    end

    if response.out then
      append_response(response.out)
    end

    if response.value then
      append_response(response.value)
    end

    if not response_data then
      append_response(vim.inspect(response))
    end

    vim.api.nvim_buf_set_option(prompt_buffer, 'modifiable', true)
    vim.api.nvim_buf_set_option(prompt_buffer, "filetype", "clojure")

    for s in response_data:gmatch("[^\r\n]+") do
      vim.api.nvim_buf_set_lines(prompt_buffer, -1, -1, true, { s })
    end
  end
end

local function eval(code)
  local prompt = require('misc.prompt')
  local ns = get_namespace()

  local prompt_header = ns .. " => " .. code

  local lines = {}
  for s in prompt_header:gmatch("[^\r\n]+") do
    table.insert(lines, s)
  end

  local prompt_buffer = prompt.create(lines, {})

  repl.eval(code, ns, function(response)
    local response_data = ""

    local function append_response(text)
      if response_data ~= "" then
        response_data = response_data .. "\n"
      end
      response_data = response_data .. text
    end

    if response.err then
      append_response(response.err)
    end

    if response.out then
      append_response(response.out)
    end

    if response.value then
      append_response(response.value)
    end

    if not response_data then
      append_response(vim.inspect(response))
    end

    vim.api.nvim_buf_set_option(prompt_buffer, 'modifiable', true)
    vim.api.nvim_buf_set_option(prompt_buffer, "filetype", "clojure")

    for s in response_data:gmatch("[^\r\n]+") do
      vim.api.nvim_buf_set_lines(prompt_buffer, -1, -1, true, { s })
    end
  end)
end

function repl_ui.eval_position()
  if not repl.is_connected() then
    print("repl is not connected")
    return
  end

  local paredit = require('paredit')
  local code = paredit.get_surroundings_contents()

  eval(code)
end

function repl_ui.eval_input()
  if not repl.is_connected() then
    print("repl is not connected")
    return
  end

  local ns = get_namespace()

  local prompt_header = ns .. " => "

  eval(vim.fn.input(prompt_header))
end

function repl_ui.require_namespace()
  if not repl.is_connected() then
    print("repl is not connected")
    return
  end
  local namespace = get_namespace()

  repl.require(namespace, make_eval_callback(string.format("user => (require '%s)", namespace)))
end

repl_ui.is_connected = repl.is_connected

return repl_ui
