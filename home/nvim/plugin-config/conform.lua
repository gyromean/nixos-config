require'conform'.setup{
    formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        go = { "gofmt" },
    },
    format_on_save = {
        timeout_ms = 2000,
    },
    formatters = {
        ["clang-format"] = {
            prepend_args = { "-style", "{IndentWidth: 4, InsertBraces: true, ReflowComments: false, SpacesBeforeTrailingComments: 2, ColumnLimit: 120}" },
        },
        ["ruff_format"] = {
            prepend_args = { "format", "--line-length", "120" },
        },
    },
}
