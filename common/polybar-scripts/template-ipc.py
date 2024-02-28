#!/usr/bin/env python

import asyncio, subprocess
from enum import Enum
from utility import set_color, distribute_icons

socket_name = '/tmp/polybar_eyetimer.sock'
# finished_signal_period = 2
icon_idle = '󰝦'

q = asyncio.Queue()

# Example nastaveni vystupu
def set_output(data):
  print(f'setting output >{data}<')
  subprocess.run(['polybar-msg', 'action', 'eyetimer', 'send', data])

def exception_wrapper(func):
  async def ret_func(*args, **kwargs):
    try:
      await func(*args, **kwargs)
    except asyncio.exceptions.CancelledError:
      pass
  return ret_func

# Funkce pro 'animace'
# @exception_wrapper
# async def finished_normal():
#   set_output(' ' + set_color('blue', icon_finished) + set_color('foreground', '  0 '))
#   await asyncio.sleep(finished_signal_period)
#   await q.put('red')

# @exception_wrapper
# async def finished_red():
#   set_output(' ' + set_color('red', icon_finished) + set_color('foreground', '  0 '))
#   await asyncio.sleep(finished_signal_period)
#   await q.put('normal')

@exception_wrapper
async def print_timer(index, icon):
  set_output(' ' + set_color('blue', icon) + set_color('foreground', f' {index:2} '))
  await asyncio.sleep(60)
  await q.put('sleep')

async def socket_reader_client(reader, writer):
  while True:
    cmd = await reader.readline()
    cmd = cmd.decode().rstrip('\n')
    if len(cmd) == 0:
      return
    await q.put(cmd)

async def socket_reader_server():
  await asyncio.start_unix_server(socket_reader_client, socket_name)

# Zabiti bezicich async funkci
# def close_coros():
#   global active_color, active_sleeper
#   for coro in [active_sleeper, active_color]:
#     if coro is not None:
#       coro.cancel()

async def main():
  # global active_color, active_sleeper
  states = Enum('state', ['idle', 'counting_down', 'finished'])
  current_state = states.idle
  asyncio.create_task(socket_reader_server())
  await q.put('reset')
  while True:
    cmd = await q.get()
    match(cmd):
      case 'a':
        pass

      case 'b':
        if current_state != states.idle:
          pass

      case 'c':
        set_output(' ' + set_color('blue', icon_idle) + set_color('foreground', ' -- '))
        pass

      case 'red':
        # active_color = asyncio.create_task(finished_red())
        pass

      case 'normal':
        # active_color = asyncio.create_task(finished_normal())
        pass

      case 'reset':
        # close_coros()
        pass

asyncio.run(main())
