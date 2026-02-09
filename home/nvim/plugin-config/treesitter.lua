require("nvim-treesitter.configs").setup({
    highlight = {
        enable = true,
        disable = { "latex" },
        additional_vim_regex_highlighting = { "python" }, -- fix pro rozbity indentation kdyz je { treba ve stringu nebo komentari, viz https://github.com/nvim-treesitter/nvim-treesitter/issues/1573#issuecomment-1780727057
    },
})
