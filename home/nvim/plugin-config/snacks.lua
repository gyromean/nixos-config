local snacks = require("snacks")

snacks.config.input.enabled = true
snacks.config.picker.enabled = true
snacks.config.terminal.enabled = true
snacks.config.lazygit.config = {
    os = {
        edit = [[ [ -z "$NVIM" ] && (nvim -- {{filename}}) || (nvim --server "$NVIM" --remote-send "<C-\><C-N>:tabedit {{filename}}<CR>") ]],
        editAtLine = [[ [ -z "$NVIM" ] && (nvim +{{line}} -- {{filename}}) || (nvim --server "$NVIM" --remote-send "<C-\><C-N>:tabedit {{filename}}<CR>:{{line}}<CR>") ]],
        openDirInEditor = [[ [ -z "$NVIM" ] && (nvim -- {{dir}}) || (nvim --server "$NVIM" --remote-send "<C-\><C-N>:tabedit {{dir}}<CR>") ]],
    },
}

vim.keymap.set("n", "<leader>g", snacks.lazygit.open, { desc = "Open lazygit" })
