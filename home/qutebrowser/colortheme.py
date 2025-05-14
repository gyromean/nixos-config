# kanagawa inspired color theme
colors = {
  'bg-dark': '#1F1F28',
  'bg-mid': '#2A2A37',
  'bg-light': '#515173',
  'blue': '#7E9CD8',
  'yellow' : '#EBCB8B',
  'green' : '#96D87E',
}

# Aliases
tabs = c.colors.tabs
statusbar = c.colors.statusbar
completion = c.colors.completion

# Tabs
tabs.bar.bg = colors['bg-mid']
tabs.even.bg = colors['bg-mid']
tabs.odd.bg = colors['bg-mid']

tabs.selected.even.bg = colors['blue']
tabs.selected.odd.bg = colors['blue']
tabs.selected.even.fg = 'black'
tabs.selected.odd.fg = 'black'

tabs.indicator.start = colors['yellow']
tabs.indicator.stop = colors['blue']

# Statusbar
statusbar.normal.bg = colors['bg-mid']
statusbar.command.bg = colors['bg-mid']

# Completion
completion.category.bg = colors['bg-light']
completion.category.border.top = 'transparent'
completion.category.border.bottom = 'transparent'

completion.even.bg = colors['bg-mid']
completion.odd.bg = colors['bg-mid']

completion.item.selected.bg = colors['blue']
completion.item.selected.fg = 'black'
completion.item.selected.border.top = 'transparent'
completion.item.selected.border.bottom = 'transparent'
