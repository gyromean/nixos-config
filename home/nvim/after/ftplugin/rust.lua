vim.opt.formatoptions:remove({ "c", "r", "o" })

-- vim.opt.tabstop = 4
-- vim.opt.softtabstop = 4
-- vim.opt.shiftwidth = 4
-- vim.opt.expandtab = true

vim.keymap.set(
    { "n", "x" },
    "<leader>p",
    [[:s/\v^( *)(.*)/\1eprintln!("\2 = {:?}", (\2));<CR>:noh<CR>]],
    { buffer = true }
)
vim.keymap.set(
    { "n", "x" },
    "<leader>P",
    [[:s/\v^( *)(.*)/\1eprintln!("\2 = {:#?}", (\2));<CR>:noh<CR>]],
    { buffer = true }
)
