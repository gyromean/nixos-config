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

        vim.keymap.set("n", "<leader>ds", gs.preview_hunk_inline, { buffer = bufnr, desc = "Git [d]iff [s]how" })
        vim.keymap.set("n", "<leader>db", gs.blame_line, { buffer = bufnr, desc = "Git [d]iff [b]lame" })
        vim.keymap.set("n", "<leader>dB", gs.blame, { buffer = bufnr, desc = "Git [d]iff [B]lame all" })
    end,
})
