#!/usr/bin/env python

import sys, subprocess, asyncio, glob, socket
from utility import set_color, distribute_icons

monitor_bus_map = { # pri pouziti bus number je to rychlejsi
  'DP-0': '6',
  'DP-2': '7',
  'DP-4': '8',
}

icon_pool = ['󰃞', '󰃟', '󰃠']
icons_distributed = distribute_icons(21, icon_pool)

polybar_pid = sys.argv[1]
monitor_bus_number = monitor_bus_map[sys.argv[2]]
socket_name = f'/tmp/polybar_brightness_{polybar_pid}.sock'

q = asyncio.Queue()

def set_output_raw(data):
  print(f'setting output >{data}<')
  return subprocess.run(['polybar-msg', '-p', polybar_pid, 'action', 'desktop-brightness', 'send', data]).returncode

def set_output(color, value):
  icon_index = value // 5
  data = set_color(color, icons_distributed[icon_index]) + set_color('foreground', f' {value}%')
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

def get_brightness(monitor_bus_number):
  comp_proc = subprocess.run(['ddcutil', '--sleep-multiplier', '1', '-t', '--bus', monitor_bus_number, 'getvcp', '10'], capture_output=True)
  print(f'{comp_proc.stdout = }')
  return int(comp_proc.stdout.decode().split()[3])

def set_brightness(monitor_bus_number, value):
  subprocess.run(['ddcutil', '--sleep-multiplier', '1', '-t', '--bus', monitor_bus_number, 'setvcp', '10', str(value)], capture_output=True)

def apply_to_all(value):
  sockets_paths = glob.glob('/tmp/polybar_brightness_*.sock')
  for socket_path in sockets_paths:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(socket_path)
    s.sendall(f'apply_val {value}'.encode())

async def main():
  curr_brightness = get_brightness(monitor_bus_number) // 5 * 5
  next_brightness = curr_brightness
  asyncio.create_task(socket_reader_server())
  while set_output('blue', curr_brightness) != 0:
    pass
  while True:
    cmd = (await q.get()).split()
    print(f'{cmd = }')
    match(cmd):
      case ['apply']:
        if next_brightness != curr_brightness:
          set_brightness(monitor_bus_number, next_brightness)
          curr_brightness = next_brightness

      case ['apply_val', value]:
        next_brightness = int(value)
        await q.put('apply')

      case ['apply_to_all']:
        apply_to_all(next_brightness)

      case ['increase']:
        if next_brightness < 100:
          next_brightness += 5

      case ['decrease']:
        if next_brightness > 0:
          next_brightness -= 5

      case ['abort']:
        next_brightness = curr_brightness
    if cmd != 'apply_to_all':
      set_output('blue' if next_brightness == curr_brightness else 'yellow', next_brightness)

asyncio.run(main())
