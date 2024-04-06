local harpoon = require'harpoon'

harpoon:setup()

vim.keymap.set("n", "<leader>ha", function() harpoon:list():append() end, {desc = "[H]arpoon [a]ppend"})
vim.keymap.set("n", "<leader>hs", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, {desc = "[H]arpoon [s]how"})

vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, {desc = "Harpoon select [1]. buffer"})
vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, {desc = "Harpoon select [2]. buffer"})
vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, {desc = "Harpoon select [3]. buffer"})
vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, {desc = "Harpoon select [4]. buffer"})
vim.keymap.set("n", "<leader>5", function() harpoon:list():select(5) end, {desc = "Harpoon select [5]. buffer"})
vim.keymap.set("n", "<leader>6", function() harpoon:list():select(6) end, {desc = "Harpoon select [6]. buffer"})
