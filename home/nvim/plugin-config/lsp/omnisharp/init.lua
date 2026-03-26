local M = {}

local util = require("lspconfig.util")
local omnisharp_extended_ok, omnisharp_extended = pcall(require, "omnisharp_extended")
local default_capabilities = require("cmp_nvim_lsp").default_capabilities()
local uv = vim.uv
local csharp_settings_filename = ".nvim-csharp-settings.json"

if omnisharp_extended_ok then
    local location_utils = require("location_utils")
    local original_qflist_list_or_jump = location_utils.qflist_list_or_jump
    local original_telescope_list_or_jump = location_utils.telescope_list_or_jump

    -- OmniSharp metadata jumps sometimes point past the end of generated buffers.
    -- Clamp the location before opening it so `gd` into framework symbols works.
    local function clamp_location(location)
        local uri = location.uri or location.targetUri
        local range = location.range or location.targetSelectionRange
        if not uri or not range or not range.start then
            return location
        end

        local bufnr = vim.uri_to_bufnr(uri)
        vim.fn.bufload(bufnr)

        local line_count = vim.api.nvim_buf_line_count(bufnr)
        if line_count == 0 then
            return location
        end

        local start_line = math.min(range.start.line, line_count - 1)
        local line_text = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 1, false)[1] or ""
        local start_char = math.min(range.start.character, #line_text)

        local safe_location = vim.deepcopy(location)
        local safe_range = vim.deepcopy(range)
        safe_range.start.line = start_line
        safe_range.start.character = start_char

        if safe_range["end"] then
            safe_range["end"].line = math.min(safe_range["end"].line, line_count - 1)
            local end_line_text = vim.api.nvim_buf_get_lines(
                bufnr,
                safe_range["end"].line,
                safe_range["end"].line + 1,
                false
            )[1] or ""
            safe_range["end"].character = math.min(safe_range["end"].character, #end_line_text)
        end

        if safe_location.range then
            safe_location.range = safe_range
        else
            safe_location.targetSelectionRange = safe_range
        end

        return safe_location
    end

    location_utils.qflist_list_or_jump = function(locations, lsp_client)
        if #locations == 1 then
            local show_document = vim.lsp.util.show_document or vim.lsp.util.jump_to_location
            show_document(clamp_location(locations[1]), lsp_client.offset_encoding)
            return
        end

        return original_qflist_list_or_jump(locations, lsp_client)
    end

    location_utils.telescope_list_or_jump = function(title, params, locations, lsp_client, opts)
        if #locations == 1 then
            locations[1] = clamp_location(locations[1])
        end

        return original_telescope_list_or_jump(title, params, locations, lsp_client, opts)
    end
end

local function path_exists(path)
    return path and uv.fs_stat(path) ~= nil
end

local function read_file(path)
    local fd = io.open(path, "r")
    if not fd then
        return nil
    end

    local content = fd:read("*a")
    fd:close()
    return content
end

local function read_json_file(path)
    local content = read_file(path)
    if not content then
        return nil
    end

    local ok, parsed = pcall(vim.json.decode, content)
    if not ok or type(parsed) ~= "table" then
        return nil
    end

    return parsed
end

local function write_json_file(path, value)
    local fd = io.open(path, "w")
    if not fd then
        return false
    end

    fd:write(vim.json.encode(value))
    fd:write("\n")
    fd:close()
    return true
end

local function get_git_root(fname)
    return util.root_pattern(".git")(fname)
end

local function get_repo_csharp_settings(fname)
    local git_root = get_git_root(fname)
    if not git_root then
        return nil
    end

    -- A repo-local settings file can point to the canonical nested solution while
    -- keeping the actual LSP workspace at the repository root for cross-project navigation.
    local settings_path = git_root .. "/" .. csharp_settings_filename
    local settings = read_json_file(settings_path)
    if not settings then
        return nil
    end

    local solution_path = settings.solution
    if type(solution_path) ~= "string" or vim.trim(solution_path) == "" then
        return nil
    end

    solution_path = vim.trim(solution_path)
    if path_exists(git_root .. "/" .. solution_path) then
        settings.root_dir = git_root
        settings.solution = solution_path
        return settings
    end

    return nil
end

local function get_csharp_settings(fname)
    local repo_settings = get_repo_csharp_settings(fname)
    if repo_settings then
        return repo_settings
    end

    return {
        root_dir = util.root_pattern("*.sln", "*.slnx")(fname)
            or util.root_pattern("*.csproj")(fname)
            or util.root_pattern("omnisharp.json", "global.json", "Directory.Build.props", ".git")(fname),
        configuration = nil,
    }
end

local function get_settings_path(fname)
    local git_root = get_git_root(fname)
    if not git_root then
        return nil
    end

    return git_root .. "/" .. csharp_settings_filename
end

local function build_cmd(root_dir, configuration)
    local cmd = {
        "OmniSharp",
        "-s",
        root_dir,
        "-z",
        "--hostPID",
        tostring(vim.fn.getpid()),
        "--encoding",
        "utf-8",
        "--languageserver",
    }

    if type(configuration) == "string" and configuration ~= "" then
        table.insert(cmd, "MsBuild:Configuration=" .. configuration)
    end

    return cmd
end

local function get_variant_label(configuration)
    return (type(configuration) == "string" and configuration ~= "") and configuration or "default"
end

local start_omnisharp
local inactive_preproc_ns = vim.api.nvim_create_namespace("csharp_inactive_preproc")

local function notify_omnisharp(message)
    vim.schedule(function()
        vim.notify(message, vim.log.levels.INFO, { title = "OmniSharp" })
    end)
end

local function set_inactive_preproc_highlight()
    local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
    vim.api.nvim_set_hl(0, "CsInactivePreproc", {
        fg = comment.fg,
        italic = comment.italic,
        nocombine = false,
    })
end

local function get_define_constants(root_dir, configuration)
    local props = read_file(root_dir .. "/Directory.Build.props")
    if not props then
        return {}
    end

    local defines = {}
    local pattern = "<PropertyGroup Condition=\"[^\"]*%$%(Configuration%)' == '" .. vim.pesc(configuration or "")
        .. "'[^\"]*\">(.-)</PropertyGroup>"
    local group = props:match(pattern)
    if not group then
        return defines
    end

    local constants = group:match("<DefineConstants>(.-)</DefineConstants>")
    if not constants then
        return defines
    end

    for constant in constants:gmatch("[^;]+") do
        defines[vim.trim(constant)] = true
    end

    return defines
end

local function tokenize_if_expression(expr)
    local tokens = {}
    local i = 1
    while i <= #expr do
        local two = expr:sub(i, i + 1)
        local one = expr:sub(i, i)
        if one:match("%s") then
            i = i + 1
        elseif two == "&&" or two == "||" then
            table.insert(tokens, two)
            i = i + 2
        elseif one == "!" or one == "(" or one == ")" then
            table.insert(tokens, one)
            i = i + 1
        else
            local ident = expr:match("^[%a_][%w_]*", i)
            if not ident then
                return nil
            end
            table.insert(tokens, ident)
            i = i + #ident
        end
    end

    return tokens
end

local function eval_if_expression(expr, defines)
    local tokens = tokenize_if_expression(expr)
    if not tokens then
        return false
    end

    local idx = 1
    local parse_or, parse_and, parse_not, parse_primary

    parse_primary = function()
        local token = tokens[idx]
        if token == "(" then
            idx = idx + 1
            local value = parse_or()
            if tokens[idx] == ")" then
                idx = idx + 1
            end
            return value
        end

        idx = idx + 1
        if token == "true" then
            return true
        end
        if token == "false" then
            return false
        end
        return defines[token] == true
    end

    parse_not = function()
        if tokens[idx] == "!" then
            idx = idx + 1
            return not parse_not()
        end
        return parse_primary()
    end

    parse_and = function()
        local value = parse_not()
        while tokens[idx] == "&&" do
            idx = idx + 1
            value = value and parse_not()
        end
        return value
    end

    parse_or = function()
        local value = parse_and()
        while tokens[idx] == "||" do
            idx = idx + 1
            value = value or parse_and()
        end
        return value
    end

    return parse_or()
end

local function mark_inactive_preproc(bufnr)
    if vim.bo[bufnr].filetype ~= "cs" then
        return
    end

    local settings = get_csharp_settings(vim.api.nvim_buf_get_name(bufnr))
    if not settings.root_dir then
        return
    end

    local defines = get_define_constants(settings.root_dir, settings.configuration)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local stack = {}
    local current_active = true

    vim.api.nvim_buf_clear_namespace(bufnr, inactive_preproc_ns, 0, -1)

    local function shade_line(row, line)
        vim.api.nvim_buf_set_extmark(bufnr, inactive_preproc_ns, row, 0, {
            end_row = row,
            end_col = #line,
            hl_group = "CsInactivePreproc",
        })
    end

    for row, line in ipairs(lines) do
        local expr = line:match("^%s*#if%s+(.+)$")
        if expr then
            local branch_active = current_active and eval_if_expression(expr, defines)
            if not branch_active then
                shade_line(row - 1, line)
            end
            table.insert(stack, {
                parent_active = current_active,
                branch_taken = branch_active,
                current_active = branch_active,
            })
            current_active = branch_active
        else
            expr = line:match("^%s*#elif%s+(.+)$")
            if expr and #stack > 0 then
                local top = stack[#stack]
                local branch_active = top.parent_active and not top.branch_taken and eval_if_expression(expr, defines)
                if branch_active then
                    top.branch_taken = true
                end
                top.current_active = branch_active
                current_active = branch_active
                if not branch_active then
                    shade_line(row - 1, line)
                end
            elseif line:match("^%s*#else%f[%W]") and #stack > 0 then
                local top = stack[#stack]
                local branch_active = top.parent_active and not top.branch_taken
                top.branch_taken = true
                top.current_active = branch_active
                current_active = branch_active
                if not branch_active then
                    shade_line(row - 1, line)
                end
            elseif line:match("^%s*#endif%f[%W]") and #stack > 0 then
                local top = table.remove(stack)
                current_active = top.parent_active
                if not current_active then
                    shade_line(row - 1, line)
                end
            elseif not current_active then
                shade_line(row - 1, line)
            end
        end
    end
end

local function refresh_inactive_preproc(root_dir)
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            if vim.bo[bufnr].filetype == "cs" and vim.startswith(bufname, root_dir .. "/") then
                mark_inactive_preproc(bufnr)
            end
        end
    end
end

local function find_omnisharp_client(root_dir, cmd)
    for _, client in ipairs(vim.lsp.get_clients({ name = "omnisharp" })) do
        if client.config.root_dir == root_dir and vim.deep_equal(client.config.cmd, cmd) then
            return client
        end
    end

    return nil
end

local function ensure_omnisharp(bufnr)
    local csharp_settings = get_csharp_settings(vim.api.nvim_buf_get_name(bufnr))
    local root_dir = csharp_settings.root_dir
    if not root_dir then
        return
    end

    local desired_cmd = build_cmd(root_dir, csharp_settings.configuration)
    local clients_to_stop = {}

    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "omnisharp" })) do
        if client.config.root_dir == root_dir and vim.deep_equal(client.config.cmd, desired_cmd) then
            return
        end

        table.insert(clients_to_stop, client.id)
    end

    local reusable_client = find_omnisharp_client(root_dir, desired_cmd)
    if reusable_client then
        vim.lsp.buf_attach_client(bufnr, reusable_client.id)
        return
    end

    for _, client in ipairs(vim.lsp.get_clients({ name = "omnisharp" })) do
        if client.config.root_dir == root_dir and not vim.deep_equal(client.config.cmd, desired_cmd) then
            table.insert(clients_to_stop, client.id)
        end
    end

    if #clients_to_stop > 0 then
        vim.lsp.stop_client(clients_to_stop, true)
        vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
                start_omnisharp(bufnr)
            end
        end, 1000)
        return
    end

    start_omnisharp(bufnr)
end

local function build_capabilities()
    return vim.tbl_deep_extend("force", default_capabilities, {
        workspace = {
            workspaceFolders = false,
        },
    })
end

local function build_settings()
    return {
        FormattingOptions = {
            EnableEditorConfigSupport = true,
            OrganizeImports = true,
        },
        MsBuild = {
            -- Load the whole solution up front so rename/definition/reference
            -- queries work across all projects instead of an on-demand subset.
            LoadProjectsOnDemand = false,
        },
        RoslynExtensionsOptions = {
            EnableAnalyzersSupport = true,
            EnableImportCompletion = true,
            AnalyzeOpenDocumentsOnly = false,
            -- Let OmniSharp provide metadata-as-source for framework types
            -- like Window and Brushes.
            EnableDecompilationSupport = true,
        },
        RenameOptions = {
            RenameInComments = true,
            RenameOverloads = true,
            RenameInStrings = true,
        },
        Sdk = {
            IncludePrereleases = true,
        },
    }
end

local function restart_omnisharp_for_root(root_dir)
    local buffers_to_restart = {}
    local client_ids = {}

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            local filetype = vim.bo[bufnr].filetype
            if (filetype == "cs" or filetype == "vb") and vim.startswith(bufname, root_dir .. "/") then
                table.insert(buffers_to_restart, bufnr)
            end
        end
    end

    for _, client in ipairs(vim.lsp.get_clients({ name = "omnisharp" })) do
        if client.config.root_dir == root_dir then
            table.insert(client_ids, client.id)
        end
    end

    if #client_ids > 0 then
        vim.lsp.stop_client(client_ids, true)
    end

    vim.defer_fn(function()
        for _, bufnr in ipairs(buffers_to_restart) do
            if vim.api.nvim_buf_is_valid(bufnr) then
                ensure_omnisharp(bufnr)
                mark_inactive_preproc(bufnr)
            end
        end
    end, 1000)
end

start_omnisharp = function(bufnr)
    local csharp_settings = get_csharp_settings(vim.api.nvim_buf_get_name(bufnr))
    local root_dir = csharp_settings.root_dir
    if not root_dir then
        return
    end

    local variant = get_variant_label(csharp_settings.configuration)
    notify_omnisharp("OmniSharp starting...")

    vim.api.nvim_buf_call(bufnr, function()
        vim.lsp.start({
            name = "omnisharp",
            cmd = build_cmd(root_dir, csharp_settings.configuration),
            cmd_env = {
                -- Allow Windows-targeted SDK resolution on Linux so WPF/Desktop
                -- reference assemblies can still be restored and analyzed.
                EnableWindowsTargeting = "true",
                -- Point OmniSharp at lightweight stub VC targets so the mixed C#/VC++
                -- solution graph can load during analysis.
                VCTargetsPath = vim.fn.expand("~/.config/nvim/plugin-config/lsp/omnisharp/msbuild"),
            },
            root_dir = root_dir,
            handlers = omnisharp_extended_ok and {
                ["textDocument/definition"] = omnisharp_extended.handler,
            } or nil,
            reuse_client = function(client, config)
                return client.name == config.name
                    and client.config.root_dir == config.root_dir
                    and vim.deep_equal(client.config.cmd, config.cmd)
            end,
            on_init = function(_)
                notify_omnisharp("OmniSharp ready. Variant: " .. variant)
            end,
            capabilities = build_capabilities(),
            settings = build_settings(),
        })
    end)
end

function M.setup()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "cs", "vb" },
        callback = function(args)
            -- Start OmniSharp ourselves so we can control the exact root and environment
            -- instead of relying on generic lspconfig root detection.
            ensure_omnisharp(args.buf)
            mark_inactive_preproc(args.buf)

            vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
                buffer = args.buf,
                callback = function()
                    mark_inactive_preproc(args.buf)
                end,
            })
        end,
    })

    vim.lsp.config("omnisharp", {
        handlers = omnisharp_extended_ok and {
            ["textDocument/definition"] = omnisharp_extended.handler,
        } or nil,
        capabilities = build_capabilities(),
        settings = build_settings(),
    })

    vim.api.nvim_create_user_command("OmniSharpReload", function()
        local root_dir = get_csharp_settings(vim.api.nvim_buf_get_name(0)).root_dir
        if root_dir then
            restart_omnisharp_for_root(root_dir)
        end
    end, {})

    vim.api.nvim_create_user_command("OmniSharpVariant", function(opts)
        local current_file = vim.api.nvim_buf_get_name(0)
        local settings_path = get_settings_path(current_file)
        local settings = get_csharp_settings(current_file)
        local variant = vim.trim(opts.args)

        if not settings_path or not settings.root_dir or not settings.solution then
            vim.notify("No repo-local C# settings file found", vim.log.levels.ERROR)
            return
        end

        if variant == "" then
            vim.notify("Current OmniSharp variant: " .. (settings.configuration or "default"))
            return
        end

        settings.configuration = variant
        settings.root_dir = nil

        if not write_json_file(settings_path, settings) then
            vim.notify("Failed to write OmniSharp settings", vim.log.levels.ERROR)
            return
        end

        restart_omnisharp_for_root(vim.fs.dirname(settings_path))
        refresh_inactive_preproc(vim.fs.dirname(settings_path))
        vim.notify("Switched OmniSharp variant to " .. variant)
    end, {
        nargs = "?",
        complete = function()
            return { "Debug", "Release", "Offline", "CAD_Only", "Lambda" }
        end,
    })

    vim.api.nvim_create_user_command("OmniSharpInfo", function()
        local current_file = vim.api.nvim_buf_get_name(0)
        local settings = get_csharp_settings(current_file)
        local client = vim.lsp.get_clients({ bufnr = 0, name = "omnisharp" })[1]
        local active_cmd = client and table.concat(client.config.cmd, " ") or "not attached"

        vim.notify(table.concat({
            "root: " .. (settings.root_dir or "unknown"),
            "solution: " .. (settings.solution or "none"),
            "variant: " .. (settings.configuration or "default"),
            "client: " .. active_cmd,
        }, "\n"))
    end, {})

    set_inactive_preproc_highlight()
end

function M.get_navigation_overrides(client)
    local definition = vim.lsp.buf.definition
    local type_definition = vim.lsp.buf.type_definition

    if client and client.name == "omnisharp" and omnisharp_extended_ok then
        -- Plain LSP definition jumps do not handle OmniSharp metadata buffers well.
        -- Use omnisharp_extended so framework symbols open generated source cleanly.
        definition = omnisharp_extended.lsp_definition
        type_definition = omnisharp_extended.lsp_type_definition
    end

    return {
        definition = definition,
        type_definition = type_definition,
    }
end

return M
