#!/usr/bin/env python

import asyncio, subprocess

from polybaripc import PolybarIPC
from utility import set_color as sc, choose_icon

icons_speaker = ['󰕿', '󰖀', '󰕾']
icon_speaker_muted = '󰸈'
icon_earbuds = '󱡏'
icon_earbuds_muted = '󱡐'

def set_volume(value, sink='@DEFAULT_SINK@'):
  subprocess.run(['wpctl', 'set-volume', str(sink), f'{value}%'])

def get_volume(sink='@DEFAULT_SINK@'):
  comp_proc = subprocess.run(['wpctl', 'get-volume', str(sink)], capture_output=True)
  output = comp_proc.stdout.decode().strip()
  volume = int(output.split(' ')[1].replace('.', ''))
  return volume

# state is '1' for mute, '0' for unmute, or 'toggle'
def set_mute(state='toggle', sink='@DEFAULT_SINK@'):
  subprocess.run(['wpctl', 'set-mute', str(sink), str(state)])

# returns True if muted, False otherwise
def get_mute(sink='@DEFAULT_SINK@'):
  comp_proc = subprocess.run(['pactl', 'get-sink-mute', str(sink)], capture_output=True)
  output = comp_proc.stdout.decode().strip()
  mute_str = output.split(': ')[1]
  return False if mute_str == 'no' else True

class Impl(PolybarIPC):
  def __init__(self, headphones_mac, *args, **kwargs):
    super().__init__(*args, **kwargs)
    self.headphones_mac = headphones_mac
    self.volume = get_volume() // 5 * 5
    self.mute = get_mute()
    self.bt_connected = self.is_bluetooth_connected() # NOTE: for future use

  def is_bluetooth_connected(self):
    comp_proc = subprocess.run(['bluetoothctl', 'info', self.headphones_mac], capture_output=True)
    output = comp_proc.stdout.decode()
    connected_lines = list(filter(lambda line: line.strip().startswith('Connected'), output.splitlines()))
    is_connected = len(connected_lines) and connected_lines[0].endswith('yes')
    return is_connected

  # NOTE: for monitoring bluetooth connection, not used currently
  # TODO: implement monitoring whether bluetooth headphones are in range
  async def bluetooth_checker(self):
    while True:
      is_connected = self.is_bluetooth_connected()
      if self.bt_connected != is_connected:
        self.bt_connected = is_connected
        self.output()
      await asyncio.sleep(1)

  def output(self):
    icon = None
    match([self.bt_connected, self.mute]):
      case False, False:
        icon = choose_icon(icons_speaker, 0, 100, self.volume)
      case False, True:
        icon = icon_speaker_muted
      case x:
        print('tady to spadlo', x)
    data = sc('blue', icon) + sc('foreground', f' {self.volume}%')
    self.update(data)

  def increase_volume(self):
    self.volume += 5
    self.output()
    set_volume(self.volume)

  def decrease_volume(self):
    if self.volume >= 5:
      self.volume -= 5
    self.output()
    set_volume(self.volume)

  def toggle_mute(self):
    self.mute = not self.mute
    self.output()
    set_mute()

  async def process_cmd(self, cmd):
    match(cmd):
      case 'up':
        self.increase_volume()

      case 'down':
        self.decrease_volume()

      case 'left':
        self.toggle_mute()

      case 'reset':
        self.output()

a = Impl('00:C5:85:68:86:3E', 'audio', 'audio')

# a.create_tasks(a.bluetooth_checker()) # NOTE: uncomment when implementing bluetooth

a.run('reset')
