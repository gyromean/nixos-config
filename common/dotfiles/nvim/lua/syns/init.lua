local M = {}

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local entry_display = require('telescope.pickers.entry_display')

local function load_python_file(path)
  local plugin_path = string.match(debug.getinfo(1).source:sub(2), "^.*/")
  vim.cmd(':pyfile ' .. plugin_path .. path)
end

local function set_highlight_groups()
  -- vim.api.nvim_set_hl(0, "SynsSynHigh", { fg = "#88c0d0" }) -- these are to original colors
  -- vim.api.nvim_set_hl(0, "SynsSynMid", { fg = "#507580" })
  -- vim.api.nvim_set_hl(0, "SynsSynLow", { fg = "#324b52" })

  vim.api.nvim_set_hl(0, "SynsSynHigh", { fg = "#88c0d0" })
  vim.api.nvim_set_hl(0, "SynsSynMid", { fg = "#618894" })
  vim.api.nvim_set_hl(0, "SynsSynLow", { fg = "#46626B" })

  vim.api.nvim_set_hl(0, "SynsAntHigh", { fg = "#ebcb8b" }) -- 92
  vim.api.nvim_set_hl(0, "SynsAntMid", { fg = "#B89F6D" }) -- 72
  vim.api.nvim_set_hl(0, "SynsAntLow", { fg = "#85734E" }) -- 52
end
local function get_url(url, python_method)
  local response = vim.fn.pyeval('Syns().' .. python_method .. '("' .. url .. '")')
  if type(response) == 'string' then
    vim.print(response)
    return nil
  end
  return response[1], response[2]
end

local function should_capitalize_output(input) -- returns true if only the first character is capitalized
  local counter = 0
  local last_upper_index = 0
  for i = 1, #input do
    local c = string.sub(input, i, i)
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

local function replace_word(selection, request, new_word)
  if should_capitalize_output(request) then
    new_word = capitalize_first_letter(new_word)
  end
  if selection ~= nil then -- visual mode
    vim.api.nvim_buf_set_text(selection.buf, selection.start_row, selection.start_col, selection.end_row, selection.end_col, { new_word })
    return
  end

  -- normal mode, replace word under cursor
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()

  local left_match = string.match(line:sub(1, col), "[a-zA-Z]+$")
  local right_match = string.match(line:sub(col, #line), "^[a-zA-Z]+")

  local left_line = line:sub(1, col - #left_match)
  local right_line = line:sub(col + #right_match, #line)

  local new_line = left_line .. new_word .. right_line
  vim.api.nvim_set_current_line(new_line)
end

-- https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md
-- https://github.com/nvim-telescope/telescope.nvim/blob/c2b8311dfacd08b3056b8f0249025d633a4e71a8/lua/telescope/make_entry.lua#L1208

-- request - original word under cursor
-- words - synonyms/antonyms for telescope to display
-- selection - information about selection if in visual mode, nil in normal mode
-- display_name - message to display in telescope (synonyms vs antonyms)
-- opts - additional options for telescope
local function query_telescope(request, words, selection, display_name, opts)
  opts = opts or {}
  local picker = pickers.new(opts, {
    prompt_title = display_name .. " of '" .. request .. "'",

    finder = finders.new_table {
      results = words,
      entry_maker = function(entry)
        -- vim.print(entry)
        local displayer = entry_display.create({ -- specifies the design of entry (widths and separator)
          separator = '',
          items = {
            { width = .5 },
            { width = .25 },
            { remaining = true },
          },
        })

        local make_display = function(entry) -- applies the defined design to an entry
          local prio_to_highlight_group = {
            [100] = 'SynsSynHigh',
            [50] = 'SynsSynMid',
            [10] = 'SynsSynLow',
            [-100] = 'SynsAntHigh',
            [-50] = 'SynsAntMid',
            [-10] = 'SynsAntLow',
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
          ordinal = entry[1] .. entry[3] .. entry[4], -- this is what is the searched text matched against
          display = make_display, -- uses the make_display function to stylize each entry
        }
      end
    },

    sorter = conf.generic_sorter(opts), -- TODO: kdyz uz to podle neceho vyfiltruju tak se to nesorti sekundarne podle toho similarity score, to by chtelo fixnout

    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selected_option = action_state.get_selected_entry().value[1]
        vim.print(action_state.get_selected_entry())
        replace_word(selection, request, selected_option)
      end)
      return true
    end,
  })
  picker:find()
end

local function query(specialized_get_url, opts)
  local mode = vim.api.nvim_get_mode().mode
  local request
  local selection
  if mode == 'n' then -- normal mode, get word under cursor
    request = vim.fn.expand("<cword>")
    selection = nil
  else -- visual mode
    local pos_a = vim.fn.getpos("v")
    local pos_b = vim.fn.getpos(".")

    local buf = pos_a[1]
    local start_row = pos_a[2] - 1
    local start_col = pos_a[3]

    local end_row = pos_b[2] - 1
    local end_col = pos_b[3]

    if start_row ~= end_row then
      print("Selection must not span multiple lines")
      return
    end

    if start_col > end_col then
      local tmp = start_col
      start_col = end_col
      end_col = tmp
    end
    start_col = start_col - 1

    request = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})[1]
    selection = {
      buf = buf,
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
    }
  end

  local words, display_name = specialized_get_url(request)

  if words == nil then
    return
  end

  query_telescope(request, words, selection, display_name, opts)
end

function M.query_synonyms(opts)
  return query(function(url)
    return get_url(url, 'query_synonyms')
  end, opts)
end

function M.query_antonyms(opts)
  return query(function(url)
    return get_url(url, 'query_antonyms')
  end, opts)
end

load_python_file('syns-eval.py')
set_highlight_groups()

return M
