#!/usr/bin/env python

from polybaripc import PolybarIPC
import asyncio

class ExampleImplementation(PolybarIPC):
  async def example_task(self, text): # this doesn't use self, so it could be static method or normal function as well
    print(text)

  @PolybarIPC.cancellable
  async def blinker(self): # corutine, on which is called .cancel() later, should be wrapped in the PolybarIPC.cancellable wrapper
    while True:
      self.update('PING')
      await asyncio.sleep(1)
      self.update('PONG')
      await asyncio.sleep(1)


  async def process_cmd(self, cmd):
    match(cmd):
      case 'left':
        self.update('custom msg')
        # await self.push_cmd('') # this is how you manually enque another command

      case 'right':
        self.blinker_task = self.create_task(self.blinker()) # this way user can create blinker multiple times, this is not a good idea

      case 'middle':
        self.blinker_task.cancel() # always make sure blinker_task is actually a task, not None

      case _:
        self.update(cmd)


a = ExampleImplementation('aaa', 'bbb') # usually there is no reason to differenciate module_name and socket_identifier (one counterexample could be desktop-brightness module, where we need to differenciate between polybars on different monitors. In such case we can, for example, append polybar's PID to the socket_identifier)
a.create_task(a.example_task('Runs immediately after calling a.run()'))
a.create_task(a.example_task('Runs 2 seconds after calling a.run()'), 2)
input('All tasks start after callling a.run(), pres enter...')
a.blinker_task = None
a.run('test') # pass initial cmd to be enqued, can be omitted

# example configuration in common/dotfiles/polybar/config.ini
'''
[module/aaa]
type = custom/ipc
hook-0 = echo 'Initial value set from polybar itself'
initial = 1
click-left = "echo left | /run/current-system/sw/bin/nc -w0 -U /tmp/polybar_bbb.sock"
click-right = "echo right | /run/current-system/sw/bin/nc -w0 -U /tmp/polybar_bbb.sock"
click-middle = "echo middle | /run/current-system/sw/bin/nc -w0 -U /tmp/polybar_bbb.sock"
scroll-up = "echo up | /run/current-system/sw/bin/nc -w0 -U /tmp/polybar_bbb.sock"
scroll-down = "echo down | /run/current-system/sw/bin/nc -w0 -U /tmp/polybar_bbb.sock"
'''
