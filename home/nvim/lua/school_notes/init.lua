local M = {
    pid = nil,
    slides_id = nil,
    slides_path = nil,
}

-- ----------------------------------------

local function scheduled_print(fmt, ...)
    local args = { ... }
    vim.schedule(function()
        vim.print(string.format(fmt, unpack(args)))
    end)
end

local function get_random_id()
    return tostring(math.random(bit.lshift(1, 30)))
        .. tostring(math.random(bit.lshift(1, 30)))
        .. tostring(math.random(bit.lshift(1, 30)))
end

-- ----------------------------------------

local function get_slide_num()
    local cmd = string.format(
        "busctl get-property --user org.pwmt.zathura.PID-%s /org/pwmt/zathura org.pwmt.zathura pagenumber",
        M.pid
    )

    local res = vim.system({ "bash", "-c", cmd }):wait()
    local num = tonumber(res.stdout:match("%d+"))
    return num + 1
end

local function get_time()
    local cmd = "printf %s $(date +%-H:%M)" -- printf for trimming trailing space

    local res = vim.system({ "bash", "-c", cmd }):wait()
    return res.stdout
end

-- ----------------------------------------

local function insert_line(str)
    local buf = vim.api.nvim_get_current_buf()
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, { str })
    vim.api.nvim_win_set_cursor(0, { line_count + 1, #str })
    vim.cmd("startinsert!")
end

local function update_state()
    if M.pid == nil then
        return
    end
    -- print("pid pred update_state: ", M.pid)
    local cmd = string.format("kill -0 %s", M.pid)
    -- print("poustim string:", cmd)
    vim.system({ "bash", "-c", cmd }, {}, function(obj)
        -- scheduled_print("obj.code: %d", obj.code)
        if obj.code ~= 0 then
            M.pid = nil
        end
    end):wait()
    -- print("pid po update_state: ", M.pid)
    -- TODO: volat to na zacatku M.start, M.normal_note a M.minimal_note
end

local function launch_zathura(slides_path)
    local pid_path = "/tmp/neovim-school-notes-pid-" .. get_random_id()
    local zathura_cmd =
        string.format("zathura %s & echo $! > %s", vim.fn.shellescape(slides_path), vim.fn.shellescape(pid_path))
    vim.system({ "bash", "-c", zathura_cmd })

    local pid_cmd = string.format("while ! cat %s 2>/dev/null; do sleep .1; done; rm %s", pid_path, pid_path)
    vim.system({ "bash", "-c", pid_cmd }, { text = true }, function(obj)
        local pid = tonumber((obj.stdout or ""):match("%d+"))
        if pid then
            vim.schedule(function()
                M.pid = pid
                print("School notes started")
            end)
        else
            scheduled_print("Error: could not read zathura PID")
        end
    end)
end

function M.start()
    update_state()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local slides_id = nil

    for i = #lines, 1, -1 do
        local tag = lines[i]:match("^%-%-%s*(.-)%s*%-%-$")
        if tag then
            slides_id = tag
            break
        end
    end

    if not slides_id then
        print("Error: no '-- XX --' line found")
        return
    end
    M.slides_id = slides_id

    local slides_path = string.format("../slides/%s.pdf", slides_id)
    local stat = vim.uv.fs_stat(slides_path)

    if not stat then
        print("Error: slides not found: " .. slides_path)
        return
    end
    M.slides_path = slides_path

    launch_zathura(slides_path)
end

function M.normal_note()
    update_state()
    if M.pid == nil then
        print("Error: School notes are not running")
        return
    end
    local time = get_time()
    local num = get_slide_num()
    insert_line(string.format("%s/%d - ", time, num))
end

function M.minimal_note()
    local time = get_time()
    insert_line(string.format("%s - ", time))
end

function M.stop()
    update_state()
    if M.pid == nil then
        return
    end
    vim.system({ "kill", M.pid })
    M.pid = nil
end

return M
