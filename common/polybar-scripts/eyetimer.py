#!/usr/bin/env python

import asyncio, subprocess
from enum import Enum
from utility import set_color, choose_icon

socket_name = '/tmp/polybar_eyetimer.sock'
icon_pool = ['󰪤', '󰪣', '󰪢', '󰪡', '󰪠', '󰪟', '󰪞', '󰝦']
icon_idle = icon_pool[-1]
icon_finished = '󰪥'
finished_signal_period = 2

q = asyncio.Queue()
active_sleeper = None
active_color = None

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

@exception_wrapper
async def finished_normal():
  set_output(' ' + set_color('blue', icon_finished) + set_color('foreground', '  0 '))
  await asyncio.sleep(finished_signal_period)
  await q.put('red')

@exception_wrapper
async def finished_red():
  set_output(' ' + set_color('red', icon_finished) + set_color('foreground', '  0 '))
  await asyncio.sleep(finished_signal_period)
  await q.put('normal')

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

def close_coros():
  global active_color, active_sleeper
  for coro in [active_sleeper, active_color]:
    if coro is not None:
      coro.cancel()

async def main():
  global active_color, active_sleeper
  states = Enum('state', ['idle', 'counting_down', 'finished'])
  current_state = states.idle
  index_default = 20
  index = 20
  asyncio.create_task(socket_reader_server())
  await q.put('reset')
  while True:
    cmd = await q.get()
    match(cmd):
      case 'sleep':
        if index > 0:
          active_sleeper = asyncio.create_task(print_timer(index, choose_icon(icon_pool, 1, index_default, index)))
          index -= 1
        else:
          await q.put('red')
          current_state = states.finished

      case 'red':
        active_color = asyncio.create_task(finished_red())

      case 'normal':
        active_color = asyncio.create_task(finished_normal())

      case 'reset':
        close_coros()
        set_output(' ' + set_color('blue', icon_idle) + set_color('foreground', ' -- '))
        current_state = states.idle

      case 'start':
        if current_state != states.counting_down:
          close_coros()
          index = index_default
          await q.put('sleep')
          current_state = states.counting_down

asyncio.run(main())
