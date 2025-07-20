" ----- COLORSCHEME -----
" colorscheme nord
colorscheme kanagawa-wave
" colorscheme catppuccin-mocha
hi! link TelescopeMatching Search
hi! link TelescopePreviewLine Search
hi LspDiagnosticsDefaultWarning guifg=#ebcb8b
hi LspDiagnosticsVirtualTextWarning guifg=#ebcb8b
hi LspDiagnosticsUnderlineWarning gui=undercurl guisp=#ebcb8b
hi LspDiagnosticsFloatingWarning guifg=#ebcb8b
hi LspDiagnosticsSignWarning guifg=#ebcb8b
hi CursorLine guibg=#2a2a37
" disablovani semantic highlight tokenu od lsp klienta, viz `:help lsp-semantic-highlight`
let mapleader = " "
lua << EOF
for _, group in ipairs(vim.fn.getcompletion("@lsp", "highlight")) do
  vim.api.nvim_set_hl(0, group, {})
end

vim.opt.list = true
vim.opt.listchars:append "eol:↴"

if vim.g.neovide then -- only executes inside neovide
  vim.g.neovide_floating_shadow = false
  vim.g.neovide_scale_factor = 1.0 -- see https://neovide.dev/faq.html#how-can-i-dynamically-change-the-scale-at-runtime
  local change_scale_factor = function(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
    vim.cmd'redraw!' -- without this the rescale will not be applied until some further user input which causes neovim to redraw
  end
  vim.keymap.set("n", "<C-=>", function()
    change_scale_factor(1.25)
  end)
  vim.keymap.set("n", "<C-->", function()
    change_scale_factor(1/1.25)
  end)
  vim.keymap.set("n", "<C-0>", function()
    vim.g.neovide_scale_factor = 1.0
    change_scale_factor(1)
  end)
  vim.keymap.set({'n', 'i', 'v', 's', 'c', 'o', 't'}, "<C-S-n>", function()
    local cwd = vim.fn.getcwd()
    vim.system({'bash', '-c', 'alacritty --working-directory ' .. cwd .. '&'}) -- workaround for hyprland window swallowing
  end)
end

vim.keymap.set({"n", "x"}, "<leader>rs", function() require'syns'.request_synonyms() end)
vim.keymap.set({"n", "x"}, "<leader>ra", function() require'syns'.request_antonyms() end)
vim.keymap.set({"n", "x"}, "<leader>rt", function() require'syns'.request_translation() end)
vim.keymap.set({"n"}, "<leader>mm", "<cmd>messages<CR>")
vim.keymap.set({"n"}, "<leader>mc", "<cmd>messages clear<CR>")
vim.keymap.set({"n"}, "<leader>ms", function() require'mindmap'.start() end, {desc = "Start closest Mindmap"})
vim.keymap.set({"n"}, "<leader>me", function() require'mindmap'.stop() end, {desc = "Stop closest Mindmap"})
vim.keymap.set({"n"}, "<leader>mv", function() require'mindmap'.view() end, {desc = "View Mindmap subtree"})
vim.keymap.set({"x"}, "<c-p>", "y1vgcO<esc>P", { remap = true, desc = "Duplicate selection and comment original" })
vim.keymap.set({"i"}, "<c-return>", "<return><esc>==\"xyy\"xP_\"xC<tab>", { desc = "Enter when inside brackets/tags" })

vim.api.nvim_set_hl(0, "TrailingWhitespace", { bg = "#7E9CD8", fg = "black" })
local trailing_whitespace = function() vim.fn.matchadd("TrailingWhitespace", [[\s\+$]]) end
vim.api.nvim_create_autocmd("WinNew", {
  callback = trailing_whitespace,
})
trailing_whitespace() -- WinNew does not get called in the first window, must call manually

vim.keymap.set("n", "<leader>rw", function()
  local view = vim.fn.winsaveview()
  vim.cmd([[%s/\v\s+$//g]])
  vim.fn.winrestview(view)
end, { desc = "Remove trailing whitespaces" })
EOF

" ----- SETS -----
set nu rnu
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set ignorecase " musi byt, aby smartcase fungoval
set smartcase " search je case-insensitive az do momentu, kdy dam neco velkejma
set clipboard=unnamedplus " nastavi clipboard na systemovej clipboard
set gdefault " V substitute se dava defaultne g (replace vsude)
set breakindent " text wrap zacina na stejnym indentation levelu
set splitright " novy okna (treba pres vsplit) se oteviraji vpravo (misto defaultne nahore)
set splitbelow " novy okna se oteviraji dole (misto defaultne nahore)
set tildeop " ted kdyz se da ~ aby se menil case pisma, tak to jeste potrebuje motion (nemeni to individualni charakter)
set scrolloff=8 " pri scrollovani bude nahore a dole vzdycky aspon 8 radek (pokud teda nejsem uplne na zacatku nebo na konci souboru)
set undofile " bude existovat perzistentni historie zmen, ty pak muzu pouzivat jak z vimu tak z undo tree
set noswapfile " nebude se zakladat a pouzivat swap file
set updatetime=100 " mimo jine se bude vim-gitgutter updatovat kazdych 100 ms
set signcolumn=yes " signs (z vim-gitgutter nebo lsp) se budou vzdy ukazovat v extra sloupecku
set noshowmode " nebude dola ukazovat v jakym jsem modu, protoze to stejne vidim v airline (diky tomu muzu pouzivat `print` z lua v insert modu a bude to vide)
set termguicolors
set shortmess+=I " disable intro screen
set smartindent
set cursorline

" ----- REBINDS -----
" save a close
nnoremap <C-w> :x<CR>
" save
nnoremap <C-s> :w<CR>
" jednorazove vypne highlight ze search commandu
nnoremap <leader>n :noh<CR>
" paste v insert modu pres ctrl+v; `:h i_CTRL-R_CTRL-O`, ten <C-p> vypne to automaticky vim formatovani ktery to vetsinou posere, viz komentar pod dotazem zde https://vi.stackexchange.com/questions/12049/how-to-set-up-crtl-v-map-that-works-in-insert-mode (v tom komentu je to <C-r><C-p>, ale lepsi je <C-r><C-o> jak pouzivam ja)
inoremap <C-v> <C-r><C-o>+
" na wincmd, takze treba `space+w+s` splitne okno horizontalne, `space+w+v` splitne okno vertikalne atd.
nnoremap <leader>w <C-w>
nnoremap <C-h> :wincmd h<CR>
nnoremap <C-j> :wincmd j<CR>
nnoremap <C-k> :wincmd k<CR>
nnoremap <C-l> :wincmd l<CR>
" mazani aniz by se prepsal obsah clipboardu
noremap <leader>d "_d
" otevre Undotree, do nej preskocim jako do jinyho okna, takze <C-h>
nnoremap <leader>u :UndotreeToggle<CR>
" navigace uvnitr snippetu z autocompletu
inoremap <C-h> <cmd>lua require'luasnip'.jump(-1)<CR>
snoremap <C-h> <cmd>lua require'luasnip'.jump(-1)<CR>
inoremap <C-l> <cmd>lua require'luasnip'.jump(1)<CR>
snoremap <C-l> <cmd>lua require'luasnip'.jump(1)<CR>
inoremap <C-y> <cmd>lua require'luasnip'.jump(1)<CR>
snoremap <C-y> <cmd>lua require'luasnip'.jump(1)<CR>
" reloaduje snippety
nnoremap <leader>L <cmd>lua require'luasnip.loaders.from_lua'.load({ paths = "/home/pavel/.config/nvim/snippets" })<CR>

" vlozeni slozenych zavorek
lua <<EOF
vim.keymap.set("i", "<C-p>", "<end> {<CR>}<up><end><CR>");
vim.keymap.set("i", "<C-S-p>", "<end><CR>{<CR>}<up><end><CR>");
vim.keymap.set("n", "<leader>c", function()
  if vim.opt.formatoptions:get().r ~= true then
    print("Enabling automatic comment insertion")
    vim.opt.formatoptions:append("ro")
  else
    print("Disabling automatic comment insertion")
    vim.opt.formatoptions:remove({"r", "o"})
  end
end, { desc = "Toggle automatic [c]omment insertion" });
EOF
" search results jsou vzdy uprostred obrazovky (ted to funguje jen smerem dopredu, <C-N> je for some reason MALE n)
nnoremap <C-N> nzz
" keybinds pro DAP
nnoremap <leader>dt <cmd>lua require'dapui'.toggle()<CR>
nnoremap <leader>db <cmd>lua require'dap'.toggle_breakpoint()<CR>
nnoremap <leader>dB <cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>
" RAISE-e (nemuzu F11, protoze to catchuje xfce4-terminal)
noremap <F4> <cmd>lua require'dap'.step_out()<CR>
" RAISE-r
noremap <F5> <cmd>lua require'dap'.restart()<CR>
" RAISE-t
noremap <F6> <cmd>lua require'dap'.terminate()<CR>
" RAISE-1
noremap <F7> <cmd>lua require'dap.ui.widgets'.centered_float(require'dap.ui.widgets'.frames)<CR>
" RAISE-2
noremap <F8> <cmd>lua require'dap'.continue()<CR>
" RAISE-3
noremap <F9> <cmd>lua require'dap'.step_over()<CR>
" RAISE-4
noremap <F10> <cmd>lua require'dap'.step_into()<CR>
" RAISE-6
xnoremap <F12> "xy \| <cmd> lua require'dapui'.eval(vim.fn.getreg("x"))<CR>
nnoremap <F12> <cmd> lua require'dapui'.eval(vim.fn.expand("<cword>"))<CR>

lua << EOF
  vim.api.nvim_create_user_command('DapResetExecutable', function()
    vim.g.dap_selected_program = nil
  end, { nargs = 0 })
  vim.api.nvim_create_user_command('DapResetArgs', function()
    vim.g.dap_selected_program_args = nil
  end, { nargs = 0 })
EOF

" ----- PLUGIN SETTINGS -----
luafile ~/.config/nvim/plugin-config/commentary.lua
luafile ~/.config/nvim/plugin-config/treesitter.lua
luafile ~/.config/nvim/plugin-config/cmp.lua
luafile ~/.config/nvim/plugin-config/treesitter-context.lua
luafile ~/.config/nvim/plugin-config/telescope.lua
luafile ~/.config/nvim/plugin-config/dap.lua
luafile ~/.config/nvim/plugin-config/lualine.lua
luafile ~/.config/nvim/plugin-config/ts-autotag.lua
luafile ~/.config/nvim/plugin-config/luasnip.lua
luafile ~/.config/nvim/plugin-config/todo-comments.lua
luafile ~/.config/nvim/plugin-config/vimtex.lua
luafile ~/.config/nvim/plugin-config/gitgutter.lua
luafile ~/.config/nvim/plugin-config/harpoon.lua
luafile ~/.config/nvim/plugin-config/oil.lua
luafile ~/.config/nvim/plugin-config/surround.lua
luafile ~/.config/nvim/plugin-config/leap.lua
luafile ~/.config/nvim/plugin-config/lazydev.lua
luafile ~/.config/nvim/plugin-config/aerial.lua
luafile ~/.config/nvim/plugin-config/lsp.lua
