--[[
write:
```
<<MM <name>
>>
```
and start writing tree inside of the tags; launch by calling start() and finish by calling stop()
]]--

local M = {
  map_count = 0,
  maps = {},
  autocmd = nil,
}

local uv = vim.uv

local stop_map, send_maps_from_buf

local function start_socket_server(map_name)

  M.maps[map_name].server = uv.new_pipe(false)
  local ok, err = M.maps[map_name].server:bind(M.maps[map_name].socket)
  if not ok then
    print("Error binding to socket: " .. err)
    return
  end

  local function on_new_connection(err)
    vim.schedule(function()
      assert(not err, err)
      -- print('Incoming connection')
      M.maps[map_name].client = uv.new_pipe(true)
      M.maps[map_name].server:accept(M.maps[map_name].client)
      M.maps[map_name].client:read_start(function(err, chunk)
        assert(not err, err)
        if not chunk then
          vim.schedule(function()
            -- print('connection se vypnul')
            stop_map(map_name)
          end)
        end
      end)
      send_maps_from_buf(0)
    end)
  end

  ok, err = M.maps[map_name].server:listen(128, on_new_connection)
  if not ok then
    print("Error listening on socket: " .. err)
    return
  end
end

local function send(map_name, data)
  if data == '' then
    data = '\n' -- workaround for sending empty data
  end
  M.maps[map_name].client:write(data)
end

local function is_line_map_start(line)
  if string.match(line, '^<<MM ') == nil then
    return nil
  end
  return string.sub(line, 6)
end

local function is_line_map_stop(line)
  return string.match(line, '^>>') ~= nil
end

send_maps_from_buf = function(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local data = ''
  local inside = false
  local map_name
  for i, line in ipairs(lines) do
    if not inside then -- outside
      map_name = is_line_map_start(line)
      if map_name ~= nil and M.maps[map_name] ~= nil then
        data = ''
        inside = true
      end
    else -- inside
      if is_line_map_stop(line) then
        send(map_name, data)
        inside = false
      else
        data = data .. line .. '\n'
      end
    end
  end
end

local function start_autocmd()
  M.autocmd = vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
    callback = function()
      local buf = tonumber(vim.fn.expand('<abuf>'))
      vim.schedule(function()
        send_maps_from_buf(buf)
      end)
    end
  })
end

local function stop_autocmd()
  if M.autocmd ~= nil then
    vim.api.nvim_del_autocmd(M.autocmd)
  end
end

local function get_closest_map(used)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local map_name = nil
  for i = cursor_line, 1, -1 do
    map_name = is_line_map_start(lines[i])
    if map_name ~= nil and ((M.maps[map_name] == nil) ~= used) then -- line contains map start tag and this map is not managed yet
        return map_name
    end
  end
  for i = cursor_line + 1, #lines do
    map_name = is_line_map_start(lines[i])
    if map_name ~= nil and ((M.maps[map_name] == nil) ~= used) then -- line contains map start tag and this map is not managed yet
        return map_name
    end
  end
  return nil
end

local function get_random_id()
  return tostring(math.random(bit.lshift(1, 30))) .. tostring(math.random(bit.lshift(1, 30))) .. tostring(math.random(bit.lshift(1, 30)))
end

-- -----------------------------------------------------------

local function start_map_gui(map_name)
  local gui_path = string.match(debug.getinfo(1).source:sub(2), "^.*/") .. 'gui.py'
  vim.system({'python', gui_path, M.maps[map_name].socket})
  -- print(vim.inspect(vim.system({'alacritty', '-e', '/run/current-system/sw/bin/python',  gui_path, M.maps[map_name].socket})))
end

local function start_map(map_name)
  M.maps[map_name] = {
    socket = '/tmp/neovim-mindmap-' .. get_random_id() .. '.sock'
  }
  M.map_count = M.map_count + 1
  start_socket_server(map_name)
  start_map_gui(map_name)
  if M.map_count == 1 then
    start_autocmd()
  end
  print('Started mindmap', map_name)
end

stop_map = function(map_name)
  if M.maps[map_name].client ~= nil then
    M.maps[map_name].client:shutdown()
    M.maps[map_name].client:close()
  end
  M.maps[map_name].server:close()

  M.maps[map_name] = nil
  M.map_count = M.map_count - 1
  if M.map_count == 0 then
    stop_autocmd()
  end
  print('Stopped mindmap', map_name)
end

-- -----------------------------------------------------------

function M.start()
  local map_name = get_closest_map(false)
  if map_name == nil then
    print('No inactive mindmap found')
    return
  end
  start_map(map_name)
end

function M.stop()
  local map_name = get_closest_map(true)
  if map_name == nil then
    print('No active mindmap found')
    return
  end
  stop_map(map_name)
end

return M
