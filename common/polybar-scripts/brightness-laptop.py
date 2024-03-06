#!/usr/bin/env python

import subprocess, asyncio
from utility import set_color, choose_icon

icon_pool = ['󰃞', '󰃟', '󰃠']
socket_name = '/tmp/polybar_brightness.sock'

q = asyncio.Queue()

def set_output_raw(data):
  print(f'setting output >{data}<')
  return subprocess.run(['polybar-msg', 'action', 'laptop-brightness', 'send', data]).returncode

def set_output(value):
  icon_index = value // 5
  data = ' ' + set_color('blue', choose_icon(icon_pool, 0, 20, icon_index)) + set_color('foreground', f' {value}% ')
  return set_output_raw(data)

async def socket_reader_client(reader, writer):
  while True:
    cmd = await reader.readline()
    cmd = cmd.decode().rstrip('\n')
    if len(cmd) == 0:
      return
    await q.put(cmd)

async def socket_reader_server():
  await asyncio.start_unix_server(socket_reader_client, socket_name)

def get_brightness():
  comp_proc = subprocess.run(['brightnessctl', 'get'], capture_output=True)
  print(f'{comp_proc.stdout = }')
  return int(comp_proc.stdout.decode())

def get_max_brightness():
  comp_proc = subprocess.run(['brightnessctl', 'max'], capture_output=True)
  print(f'{comp_proc.stdout = }')
  return int(comp_proc.stdout.decode())

def set_brightness(value):
  subprocess.run(['brightnessctl', 'set', str(value)], capture_output=True)

async def main():
  max_brightness = get_max_brightness()
  brightness = (100 * get_brightness() // max_brightness) // 5 * 5
  asyncio.create_task(socket_reader_server())
  while set_output(brightness) != 0:
    pass
  while True:
    cmd = (await q.get()).split()
    print(f'{cmd = }')
    match(cmd):
      case ['increase']:
        if brightness < 100:
          brightness += 5

      case ['decrease']:
        if brightness > 0:
          brightness -= 5

    set_brightness(brightness * max_brightness // 100)
    set_output(brightness)

asyncio.run(main())
