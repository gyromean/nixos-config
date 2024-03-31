vim.g.vimtex_view_method = 'zathura'
vim.g.vimtex_compiler_latexmk = {
  aux_dir = 'aux',
  out_dir = 'out',
  options = {
    '-shell-escape',
    '-verbose',
    '-file-line-error',
    '-synctex=1',
    '-interaction=nonstopmode',
  },
}

vim.g.vimtex_mappings_enabled = false

-- uncomment for symbolic names to display as symbols (e.g. \alpha)
-- vim.o.conceallevel = 1
-- vim.g.tex_conceal='abdmg'
