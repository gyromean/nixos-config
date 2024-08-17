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
