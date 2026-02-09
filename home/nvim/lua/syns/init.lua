local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local previewers = require("telescope.previewers")

local function execute_python_file(path)
    local plugin_path = string.match(debug.getinfo(1).source:sub(2), "^.*/")
    vim.cmd(":pyfile " .. plugin_path .. path)
end

local function get_selection()
    local mode = vim.api.nvim_get_mode().mode
    if mode == "n" then -- normal mode, get word under cursor
        local char_pool = "[a-zA-Z]"

        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local row = cursor_pos[1] - 1
        local col = cursor_pos[2] + 1
        local line = vim.api.nvim_get_current_line()

        local left_match = string.match(line:sub(1, col), char_pool .. "+$")
        if left_match == nil then
            vim.print("Selection under cursor is not a valid word")
            return nil
        end

        local right_match = string.match(line:sub(col, #line), "^" .. char_pool .. "+")

        local start_col = col - (#left_match - 1) - 1
        local end_col = col + (#right_match - 1)

        return {
            buf = vim.api.nvim_get_current_buf(),
            start_row = row,
            start_col = start_col,
            end_row = row,
            end_col = end_col,
        }
    else -- visual mode
        local pos_a = vim.fn.getpos("v")
        local pos_b = vim.fn.getpos(".")

        local buf = pos_a[1]
        local start_row = pos_a[2] - 1
        local start_col = pos_a[3]

        local end_row = pos_b[2] - 1
        local end_col = pos_b[3]

        if start_row ~= end_row then
            vim.print("Selection must not span multiple lines")
            return nil
        end

        if start_col > end_col then
            local tmp = start_col
            start_col = end_col
            end_col = tmp
        end
        start_col = start_col - 1

        return {
            buf = buf,
            start_row = start_row,
            start_col = start_col,
            end_row = end_row,
            end_col = end_col,
        }
    end
end

local function get_text_from_selection(selection)
    return vim.api.nvim_buf_get_text(
        selection.buf,
        selection.start_row,
        selection.start_col,
        selection.end_row,
        selection.end_col,
        {}
    )[1]
end

local function set_highlight_groups()
    local groups = {
        SynsSynHigh = "#88c0d0",
        SynsSynMid = "#618894",
        SynsSynLow = "#46626B",
        SynsAntHigh = "#ebcb8b",
        SynsAntMid = "#B89F6D",
        SynsAntLow = "#85734E",
    }
    for group, color in pairs(groups) do
        vim.api.nvim_set_hl(0, group, { fg = color })
    end
end

local function query_backend(python_call)
    local response = vim.fn.pyeval(python_call)
    if not response.ok then
        vim.print(response.content)
        return nil
    end
    return response.content
end

local function is_capitalized(text) -- returns true if only the first character is capitalized (so returns false for example for `OK`)
    local counter = 0
    local last_upper_index = 0
    for i = 1, #text do
        local c = string.sub(text, i, i)
        if c == string.upper(c) then
            counter = counter + 1
            last_upper_index = i
        end
    end
    return counter == 1 and last_upper_index == 1
end

local function capitalize_first_letter(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

local function set_text(selection, output_text)
    vim.api.nvim_buf_set_text(
        selection.buf,
        selection.start_row,
        selection.start_col,
        selection.end_row,
        selection.end_col,
        { output_text }
    )
end

-- https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md
-- https://github.com/nvim-telescope/telescope.nvim/blob/c2b8311dfacd08b3056b8f0249025d633a4e71a8/lua/telescope/make_entry.lua#L1208

local function run_telescope_thesaurus(input_text, response, selection, opts) -- TODO: mozna nejak prejmenovat, ale udelat custom funkci co to obaluje a vytvori a vrati mi picker kde jsou ty veci co nechci menit stejny a ostatni se daji predat parametrem, treba vnitrek toho attach_mappings (ale az ten relevantni vnitrek, takze to vzdycky closnout atd.)
    opts = opts or {}
    local picker = pickers.new(opts, {
        prompt_title = response.prompt_title,

        finder = finders.new_table({
            results = response.data,
            entry_maker = function(entry)
                local displayer = entry_display.create({ -- specifies the design of entry (widths and separator)
                    separator = "",
                    items = {
                        { width = 0.5 },
                        { width = 0.25 },
                        { remaining = true },
                    },
                })

                local make_display = function(entry) -- applies the defined design to an entry
                    local prio_to_highlight_group = {
                        [100] = "SynsSynHigh",
                        [50] = "SynsSynMid",
                        [10] = "SynsSynLow",
                        [-100] = "SynsAntHigh",
                        [-50] = "SynsAntMid",
                        [-10] = "SynsAntLow",
                    }
                    local prio = prio_to_highlight_group[entry.value[2]]
                    return displayer({
                        { entry.value[1], prio },
                        entry.value[3],
                        entry.value[4],
                    })
                end

                return {
                    value = entry, -- to je to co se pak realne returne
                    ordinal = entry[1] .. entry[3] .. entry[4], -- this specifies what the searched text is matched against
                    display = make_display, -- uses the make_display function to stylize each entry
                }
            end,
        }),

        sorter = conf.generic_sorter(opts), -- TODO: kdyz uz to podle neceho vyfiltruju tak se to nesorti sekundarne podle toho similarity score, to by chtelo fixnout

        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local output_text = action_state.get_selected_entry().value[1]
                if is_capitalized(input_text) then
                    output_text = capitalize_first_letter(output_text)
                end
                set_text(selection, output_text)
            end)
            return true
        end,
    })
    picker:find()
end

local function translation_to_plain_string(translation)
    local ret = translation[1].val
    for i = 2, #translation do
        ret = ret .. " " .. translation[i].val
    end
    return ret
end

local function translation_to_displayer_items(translation)
    local ret = {}
    for i = 1, #translation do
        table.insert(ret, {})
    end
    return ret
end

local function translation_to_displayer_call(translation)
    local ret = {}
    for _, t in ipairs(translation) do
        if t.type == "normal" then
            table.insert(ret, { t.val, "SynsSynHigh" })
        else
            table.insert(ret, { t.val, "SynsAntHigh" })
        end
    end
    return ret
end

local function definition_to_lines(definition)
    local ret = {}
    table.insert(ret, definition.meaning)
    for _, e in ipairs(definition.examples) do
        table.insert(ret, "  " .. e.src .. " -> " .. e.dst)
    end
    return ret
end

local function definitions_to_lines(definitions)
    local ret = {}
    for _, line in ipairs(definition_to_lines(definitions[1])) do
        table.insert(ret, line)
    end
    for i = 2, #definitions do
        table.insert(ret, "")
        for _, line in ipairs(definition_to_lines(definitions[i])) do
            table.insert(ret, line)
        end
    end
    return ret
end

local function run_telescope_translation(input_text, response, selection, opts)
    -- vim.print('response.data[6] = ' .. vim.inspect(response.data[6]))
    -- vim.print('response.data = ' .. vim.inspect(response.data))
    -- if true then -- TODO: odstranit
    --   return
    -- end
    opts = opts or {}
    local picker = pickers.new(opts, {
        prompt_title = response.prompt_title,

        finder = finders.new_table({
            results = response.data,
            entry_maker = function(entry)
                local displayer = entry_display.create({ -- specifies the design of entry (widths and separator)
                    separator = " ",
                    items = translation_to_displayer_items(entry.translation),
                })

                local make_display = function(entry) -- applies the defined design to an entry
                    local prio_to_highlight_group = {
                        [100] = "SynsSynHigh",
                        [50] = "SynsSynMid",
                        [10] = "SynsSynLow",
                        [-100] = "SynsAntHigh",
                        [-50] = "SynsAntMid",
                        [-10] = "SynsAntLow",
                    }
                    local prio = prio_to_highlight_group[entry.value[2]]
                    return displayer(translation_to_displayer_call(entry.value.translation))
                end

                return {
                    value = entry, -- to je to co se pak realne returne
                    ordinal = translation_to_plain_string(entry.translation), -- this specifies what the searched text is matched against -- TODO: nastavit na ten anglicky preklad
                    display = make_display, -- uses the make_display function to stylize each entry
                }
            end,
        }),

        sorter = conf.generic_sorter(opts), -- TODO: kdyz uz to podle neceho vyfiltruju tak se to nesorti sekundarne podle toho similarity score, to by chtelo fixnout

        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local output_text = action_state.get_selected_entry().value[1]
                -- set_text(selection, output_text) -- TODO: tady neco udelat
            end)
            return true
        end,

        -- inspiration from https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/builtin/__internal.lua#L455
        previewer = previewers.new_buffer_previewer({
            title = "Definitions and examples",
            define_preview = function(self, entry)
                -- vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {'bruh', 'lmao'})
                local tmp = definitions_to_lines(entry.value.definitions)
                vim.print("tmp = " .. vim.inspect(tmp))
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, tmp)
            end,
        }),
    })
    picker:find()
end

local function query(get_response, run_telescope, opts)
    local selection = get_selection()
    if selection == nil then
        return
    end
    local input_text = get_text_from_selection(selection)

    local response = get_response(input_text)
    if response == nil then
        return
    end

    run_telescope(input_text, response, selection, opts)
end

function M.request_synonyms(opts)
    return query(function(input_text)
        return query_backend('Syns().request_synonyms("' .. input_text .. '")')
    end, run_telescope_thesaurus, opts)
end

function M.request_antonyms(opts)
    return query(function(input_text)
        return query_backend('Syns().request_antonyms("' .. input_text .. '")')
    end, run_telescope_thesaurus, opts)
end

function M.request_translation(opts)
    local input_text = vim.fn.input("Word to translate: ")
    local response = query_backend('Syns.request_translation("' .. input_text .. '")')
    if response == nil then
        return
    end
    run_telescope_translation(input_text, response, {}, opts) -- TODO: vyplnit selection na aktualni kurzor asi
end

execute_python_file("syns-eval.py")
set_highlight_groups()

return M
