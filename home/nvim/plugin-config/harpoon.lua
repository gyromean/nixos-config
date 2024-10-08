# for the harpoon state to be shared via syncthing, a symlink to a folder must be created, i.e. `ln -s ~/sync/harpoon ~/.local/share/nvim/harpoon`

local harpoon = require'harpoon'

harpoon:setup({
  settings = {
    sync_on_ui_close = true,
    save_on_toggle = true,
  },
})

vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, {desc = "[H]arpoon [a]dd"})
vim.keymap.set("n", "<leader>hs", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, {desc = "[H]arpoon [s]how"})

vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, {desc = "Harpoon select [1]. buffer"})
vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, {desc = "Harpoon select [2]. buffer"})
vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, {desc = "Harpoon select [3]. buffer"})
vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, {desc = "Harpoon select [4]. buffer"})
vim.keymap.set("n", "<leader>5", function() harpoon:list():select(5) end, {desc = "Harpoon select [5]. buffer"})
vim.keymap.set("n", "<leader>6", function() harpoon:list():select(6) end, {desc = "Harpoon select [6]. buffer"})
