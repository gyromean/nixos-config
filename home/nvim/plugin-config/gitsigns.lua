require("gitsigns").setup({
    on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        vim.keymap.set("n", "[c", function()
            if vim.wo.diff then
                vim.cmd.normal({ "[c", bang = true })
            else
                gs.prev_hunk()
            end
        end, { buffer = bufnr })

        vim.keymap.set("n", "]c", function()
            if vim.wo.diff then
                vim.cmd.normal({ "]c", bang = true })
            else
                gs.next_hunk()
            end
        end, { buffer = bufnr })
    end,
})
