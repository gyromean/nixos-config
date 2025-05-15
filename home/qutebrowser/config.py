# Helper functions
def userscript(content, editable=True):
  ret = []
  if editable:
    ret.append('cmd-set-text -s')
  ret.append(':spawn --userscript')
  ret.append(content)
  return ' '.join(ret)

# Disable autoconfig loading
config.load_autoconfig(False)

# Load other config files
config.source('colortheme.py')

# Settings
c.tabs.position = 'left'
c.tabs.background = False
c.auto_save.session = True
c.tabs.select_on_remove = 'last-used'
c.editor.command = ['alacritty', '-e', 'nvim', '{file}']
c.completion.quick = False

# Binds
binds = {}
unbinds = {}

## Binds for normal mode
unbinds['normal'] = [
  'T',
]
binds['normal'] = {
  '<Ctrl-O>': 'tab-focus stack-prev',
  '<Ctrl-I>': 'tab-focus stack-next',
  'gc': 'tab-clone',
  't': 'cmd-set-text -s :tab-select',
  'Th': 'back -t',
  'Tl': 'forward -t',
  'x': 'config-cycle tabs.show never always',
  'p': 'open -t -- {clipboard}',
  'P': 'open -- {clipboard}',
  '<Ctrl-J>': 'tab-move +',
  '<Ctrl-K>': 'tab-move -',
  'D': 'tab-close -n',
  'o': 'cmd-set-text -s :open -t',
  'O': 'cmd-set-text -s :open',
  '<space>c': userscript('courses 1'),
  '<space>C': userscript('courses 0'),
  'gs': 'navigate strip',
  'gS': 'navigate -t strip',
  ';p': 'hint links userscript pdf',
  '<space>1': 'tab-focus 1',
  '<space>2': 'tab-focus 2',
  '<space>3': 'tab-focus 3',
  '<space>4': 'tab-focus 4',
  '<space>5': 'tab-focus 5',
  '<space>6': 'tab-focus 6',
  '<space>7': 'tab-focus 7',
  '<space>8': 'tab-focus 8',
  '<space>9': 'tab-focus -1',
}

## Binds for command mode
binds['command'] = {
  '<Ctrl-J>': 'completion-item-focus next',
  '<Ctrl-K>': 'completion-item-focus prev',
  '<Ctrl-y>': 'completion-item-focus next ;; command-accept',
}

## Binds for passthrough mode
binds['passthrough'] = {
  '<Shift-Space>': 'mode-leave',
}

## Binds for insert mode
binds['insert'] = {
  '<Escape>': 'mode-leave ;; jseval -q document.activeElement.blur()', # see https://github.com/qutebrowser/qutebrowser/discussions/7044
}

for mode in binds:
  for key, val in binds[mode].items():
    config.bind(key, val, mode=mode)

for mode in unbinds:
  for key in unbinds[mode]:
    config.unbind(key, mode=mode)
