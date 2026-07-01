local snacks = require("snacks")

snacks.config.input.enabled = true
snacks.config.picker.enabled = true
snacks.config.terminal.enabled = true
snacks.config.lazygit.config = {
    os = {
        edit = [[ [ -z "$NVIM" ] && (nvim -- {{filename}}) || (nvim --server "$NVIM" --remote-tab {{filename}}) ]],
        editAtLine = [[ [ -z "$NVIM" ] && (nvim +{{line}} -- {{filename}}) || (nvim --server "$NVIM" --remote-tab {{filename}} && nvim --server "$NVIM" --remote-send ":{{line}}<CR>") ]],
        openDirInEditor = [[ [ -z "$NVIM" ] && (nvim -- {{dir}}) || (nvim --server "$NVIM" --remote-tab {{dir}}) ]],
    },
}

vim.keymap.set("n", "<leader>g", snacks.lazygit.open, { desc = "Open lazygit" })
