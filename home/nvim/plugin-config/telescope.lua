require'telescope'.setup{
  defaults = {
    mappings = {
      i = {
        ["<C-j>"] = 'move_selection_next',
        ["<C-k>"] = 'move_selection_previous',
        ["<C-s>"] = 'select_horizontal',
        ["<C-p>"] = require('telescope.actions.layout').toggle_preview,
      }
    },
    path_display = { "truncate" }, -- aby se ukazovala prava cast pathu pri hledani
    preview = {
      hide_on_startup = true,
    },
  },
  pickers = {
    find_files = {
      hidden = true, -- ukazovat hidden files
      find_command = { "find", "-type", "f,l" } -- pridat prepinac `-type l`, jinak to neukazovalo linky, a tech je v NixOS hodne
    },
    live_grep = {
      additional_args = { "--hidden", "--follow" } -- ukazovat hidden files a followovat linky
    }
  }
}
require'telescope'.load_extension('fzf') -- kvuli extensionu, musi se to volat az po volani require'telescope'.setup, https://github.com/nvim-telescope/telescope-fzf-native.nvim
require'telescope'.load_extension('ui-select') -- prettier code actions

vim.keymap.set('n', '<leader>tf', require'telescope.builtin'.find_files, { desc = 'Telescope file search' })
vim.keymap.set('n', '<leader>tg', require'telescope.builtin'.git_files, { desc = 'Telescope file search' })
vim.keymap.set('n', '<leader>tk', require'telescope.builtin'.keymaps, { desc = 'Telescope keymap search' })
vim.keymap.set('n', '<leader>th', require'telescope.builtin'.help_tags, { desc = 'Telescope help search' })
vim.keymap.set('n', '<leader>tt', require'telescope.builtin'.live_grep, { desc = 'Telescope text grep' })
vim.keymap.set('x', '<leader>tt', function()
  local start_pos = vim.fn.getpos('v')
  local end_pos = vim.fn.getpos('.')

  local buf = start_pos[1]

  local start_row = start_pos[2] - 1
  local start_col = start_pos[3]
  local end_row = end_pos[2] - 1
  local end_col = end_pos[3]

  if start_row ~= end_row then
    vim.print('Selection must not span multiple lines')
    return
  end

  if start_col > end_col then
    local tmp = start_col
    start_col = end_col
    end_col = tmp
  end
  start_col = start_col - 1

  local selected_text = vim.api.nvim_buf_get_text(
    buf,
    start_row,
    start_col,
    end_row,
    end_col,
    {}
  )[1]

  require'telescope.builtin'.live_grep({ default_text = selected_text })
end, { desc = 'Grep current selection' })
