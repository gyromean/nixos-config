# Disable autoconfig loading
config.load_autoconfig(False)

# Load other config files
config.source('colortheme.py')

# Settings
c.tabs.position = 'left'
c.tabs.background = False
c.auto_save.session = True
c.tabs.select_on_remove = 'last-used'

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
  'gj': 'tab-move +',
  'gk': 'tab-move -',
  'D': 'tab-close -n',
  'o': 'cmd-set-text -s :open -t',
  'O': 'cmd-set-text -s :open',
  '<space>c': 'config-source',
}

## Binds for command mode
binds['command'] = {
  '<Ctrl-J>': 'completion-item-focus next',
  '<Ctrl-K>': 'completion-item-focus prev',

}

## Binds for passthrough mode
binds['passthrough'] = {
  '<Shift-Space>': 'mode-leave',
}

for mode in binds:
  for key, val in binds[mode].items():
    config.bind(key, val, mode=mode)

for mode in unbinds:
  for key in unbinds[mode]:
    config.unbind(key, mode=mode)
