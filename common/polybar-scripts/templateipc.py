#!/usr/bin/env python

from polybaripc import PolybarIPC

class ModuleName(PolybarIPC):
  async def process_cmd(self, cmd):
    match(cmd):
      case _:
        pass

module = ModuleName('modulename', 'modulename')
module.run('reset')
