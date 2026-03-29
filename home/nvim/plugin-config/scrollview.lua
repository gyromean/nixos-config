local function set_scrollview_highlights()
    local function transparent_bg(from, to)
        local hl = vim.api.nvim_get_hl(0, { name = from, link = false })
        if vim.tbl_isempty(hl) then
            return
        end

        hl.bg = nil
        hl.ctermbg = nil
        vim.api.nvim_set_hl(0, to, hl)
    end

    vim.api.nvim_set_hl(0, "ScrollViewDiagnosticsError", { link = "DiagnosticError" })
    vim.api.nvim_set_hl(0, "ScrollViewDiagnosticsWarn", { link = "DiagnosticWarn" })
    vim.api.nvim_set_hl(0, "ScrollViewCursor", { fg = "#98BB6C", bg = "NONE" })
    transparent_bg("GitSignsAdd", "ScrollViewGitAdd")
    transparent_bg("GitSignsChange", "ScrollViewGitChange")
    transparent_bg("GitSignsDelete", "ScrollViewGitDelete")
end

require("scrollview").setup({
    current_only = true,
    visibility = "always",
    signs_on_startup = { "cursor", "diagnostics", "search" },
    diagnostics_severities = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN },
})

require("scrollview.contrib.gitsigns").setup({
    add_highlight = "ScrollViewGitAdd",
    change_highlight = "ScrollViewGitChange",
    delete_highlight = "ScrollViewGitDelete",
})

set_scrollview_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = set_scrollview_highlights,
})
