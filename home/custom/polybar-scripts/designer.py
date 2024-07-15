#!/usr/bin/env python

from polybaripc import PolybarIPC
from utility import set_color as sc

class Impl(PolybarIPC):
  def __init__(self, *args, **kwargs):
    super().__init__(*args, **kwargs)

    self.items = [
      # FILL WITH STRINGS FOR POLYBAR, at least one must be present
      'text',
      sc('foreground', 'white ') + sc('blue', 'blue'),
    ]
    self.index = 0

    self.update(self.items[0])

  async def process_cmd(self, cmd):
    match(cmd):
      case 'up' | 'left':
        self.index += 1

      case 'down' | 'right':
        self.index -= 1

    self.index = self.index % len(self.items)
    self.update(self.items[self.index])

a = Impl('designer', 'designer')
a.run()
