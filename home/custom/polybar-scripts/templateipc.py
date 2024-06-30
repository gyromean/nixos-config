#!/usr/bin/env python

from polybaripc import PolybarIPC

class Impl(PolybarIPC):
  async def process_cmd(self, cmd):
    match(cmd):
      case _:
        pass

module = Impl('modulename', 'modulename')
module.run('reset')
