vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        local filetype = vim.bo[args.buf].filetype
        local language = vim.treesitter.language.get_lang(filetype) or filetype

        if language ~= "latex" then
            pcall(vim.treesitter.start, args.buf, language)
        end

        -- Keep regex highlighting alongside Treesitter to avoid broken Python indentation.
        if filetype == "python" then
            vim.bo[args.buf].syntax = "python"
        end
    end,
})
