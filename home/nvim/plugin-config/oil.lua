require'oil'.setup({
  keymaps = {
    ["<CR>"] = "actions.select",
    ["<BS>"] = "actions.parent",
    ["gs"] = "actions.change_sort",
    ["g."] = "actions.toggle_hidden",
  },
  use_default_keymaps = false,
})

vim.keymap.set({"n"}, "<BS>", "<cmd>Oil<cr>")
