local leap = require'leap'

vim.keymap.set({'n', 'x', 'o'}, 's',  '<Plug>(leap-forward)')
vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward)')

leap.opts.safe_labels = {}
leap.opts.equivalence_classes = {
  'aá', 'cč', 'dď', 'eéě', 'ií', 'nň', 'oó', 'rř', 'sš', 'tť', 'uúů', 'yý', 'zž'
}
