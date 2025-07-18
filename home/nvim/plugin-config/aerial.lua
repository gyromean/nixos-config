require'aerial'.setup{
  -- open_automatic = true,
  manage_folds = true,

  -- filter_kind = {
  --   "Array",
  --   "Boolean",
  --   "Class",
  --   "Constant",
  --   "Constructor",
  --   "Enum",
  --   "EnumMember",
  --   "Event",
  --   "Field",
  --   "File",
  --   "Function",
  --   "Interface",
  --   "Key",
  --   "Method",
  --   "Module",
  --   "Namespace",
  --   "Null",
  --   "Number",
  --   "Object",
  --   "Operator",
  --   "Package",
  --   "Property",
  --   "String",
  --   "Struct",
  --   "TypeParameter",
  --   "Variable",
  -- },

  nav = {
    keymaps = {
      ["q"] = "actions.close",
      ["<esc>"] = "actions.close",
    },
  },
}

vim.keymap.set("n", "<leader>A", "<cmd>AerialOpen<CR>")
vim.keymap.set("n", "<leader>a", "<cmd>AerialNavToggle<CR>")
