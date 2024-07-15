#!/usr/bin/env python

import asyncio, subprocess

from polybaripc import PolybarIPC
from utility import set_color as sc, choose_icon
from enum import Enum
import re
import sys

icons_speaker = ['󰕿', '󰖀', '󰕾']
icon_speaker_muted = '󰸈'
icon_earbuds = '󱡏'
icon_earbuds_muted = '󱡐'

states = Enum('state', ['SPEAKERS', 'BLUETOOTH'])

BLUETOOTH_MAC = '00:C5:85:68:86:3E'
BLUETOOTH_SINK = 'bluez_output.00_C5_85_68_86_3E.1'
SPEAKERS_SINK = sys.argv[1]

def run_cmd(args, timeout=None):
  comp_proc = subprocess.run(args, capture_output=True, timeout=timeout)
  return comp_proc.stdout.decode()

def set_volume(sink, value):
  run_cmd(['pactl', 'set-sink-volume', sink, f'{value}%'])

def get_volume(sink):
  while True:
    try:
      print('[get_volume] iteration')
      output = run_cmd(['pactl', 'get-sink-volume', sink], 0.5)
      percentage = re.search(r'\s(\S+)%', output).group(1)
      print('[get_volume] success')
      return int(percentage)
    except:
      pass

def set_mute(sink, action='toggle'):
  run_cmd(['pactl', 'set-sink-mute', sink, str(action)])

def get_mute(sink):
  while True:
    try:
      print('[get_mute] iteration')
      output = run_cmd(['pactl', 'get-sink-mute', sink], 0.5).strip()
      mute_str = output.split(': ')[1]
      print('[get_mute] success')
      return False if mute_str == 'no' else True
    except:
      pass

def wait_wireplumber_running(sink='@DEFAULT_SINK@'):
  while True:
    comp_proc = subprocess.run(['wpctl', 'get-volume', str(sink)], capture_output=True)
    output = comp_proc.stdout.decode().strip()
    if output != '':
      return

def select_sink(sink):
  subprocess.run(['wpctl', 'settings', 'target-sink', sink])
  subprocess.run(['wpctl', 'settings', '--save', 'target-sink'])
  subprocess.run(['pactl', 'set-default-sink', sink])

def pactl_list_sinks():
  return run_cmd(['pactl', 'list', 'sinks', 'short'])

class Impl(PolybarIPC):
  def __init__(self, *args, **kwargs):
    super().__init__(*args, **kwargs)
    wait_wireplumber_running()
    self.init_states()
    self.init_tasks()
    select_sink(SPEAKERS_SINK)
    self.refresh()

  def init_states(self): # comments denote where are the values managed
    self.volume_speakers = get_volume(SPEAKERS_SINK) // 5 * 5 # refresh
    self.mute_speakers = get_mute(SPEAKERS_SINK) # refresh
    self.volume_bluetooth = 0 # refresh
    self.mute_bluetooth = False # refresh

    self.bt_in_range = False # bt_in_range_listener
    self.bt_connected = False # refresh

    self.enum = states.SPEAKERS # managed manually
    self.automute = False # managed manually

  def init_tasks(self):
    self.create_task(self.bt_in_range_listener())
    self.create_task(self.pactl_listener())

  async def select_bluetooth(self):
    print('[select_bluetooth] starting')
    if self.bt_in_range == False \
        or self.enum == states.BLUETOOTH:
      print('[select_bluetooth] not applicable, aborting')
      return

    while self.bt_connected == False:
      if self.bt_in_range == False \
          or self.enum == states.BLUETOOTH:
        print('[select_bluetooth] not applicable, aborting')
        return
      print('[select_bluetooth] bluetooth not connected, trying to connect')
      run_cmd(['bluetoothctl', 'connect', BLUETOOTH_MAC])
      await asyncio.sleep(.5)
      self.refresh()

    print('[select_bluetooth] bluetooth connected')
    if get_mute(SPEAKERS_SINK) == False:
      print('[select_bluetooth] automuting speakers')
      set_mute(SPEAKERS_SINK, 1)
      self.automute = True
      self.mute_speakers = True
    else:
      print('[select_bluetooth] speakers already muted, no automuting')

    print('[select_bluetooth] switching sink')
    select_sink(BLUETOOTH_SINK)
    self.enum = states.BLUETOOTH

    print('[select_bluetooth] finished')

  def select_speakers(self, revert_automute=True):
    print('[select_speakers] starting')
    if self.enum == states.SPEAKERS:
      print('[select_speakers] not applicable, aborting')
      return

    if revert_automute:
      if self.automute == True:
        print('[select_speakers] unautomuting speakers')
        set_mute(SPEAKERS_SINK, 0)
        self.automute = False
        self.mute_speakers = False # reset here because output is called before refresh

    print('[select_speakers] switching sink')
    select_sink(SPEAKERS_SINK)
    self.enum = states.SPEAKERS

    print('[select_speakers] finished')

  async def switch_sink(self):
    if self.enum == states.SPEAKERS:
      await self.select_bluetooth()
    else:
      self.select_speakers()

  def refresh(self):
    self.volume_speakers = get_volume(SPEAKERS_SINK) // 5 * 5
    self.mute_speakers = get_mute(SPEAKERS_SINK)

    list_sinks = pactl_list_sinks()
    self.bt_connected = BLUETOOTH_SINK in list_sinks

    if self.bt_connected:
      self.volume_bluetooth = get_volume(BLUETOOTH_SINK) // 5 * 5
      self.mute_bluetooth = get_mute(BLUETOOTH_SINK)

    match [self.enum, self.bt_connected]:
      case [states.BLUETOOTH, False]:
        print('[refresh] headphones have disconnected, selecting speakers')
        self.select_speakers(False) # do not revert automute (also sets state to SPEAKERS)

    self.output()

  async def pactl_listener(self):
    proc = await asyncio.create_subprocess_exec('pactl', 'subscribe', stdout=asyncio.subprocess.PIPE)
    while True:
      stdout = await proc.stdout.readline()
      print("[pactl_listener] stdout:", stdout)
      if b" sink " not in stdout: # skip irrelevant events and prevent livelock (because pactl_list_sinks causes an event int pactl subscribe)
        continue
      self.refresh()

  async def bt_in_range_listener(self):
    while True:
      proc = await asyncio.create_subprocess_exec('hcitool', 'name', BLUETOOTH_MAC, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
      stdout, stderr = await proc.communicate()
      print("[bluetooth_in_range_listener] stdout:", stdout)
      print("[bluetooth_in_range_listener] stderr:", stderr)
      in_range = len(stdout.strip()) > 0

      changed = in_range != self.bt_in_range
      self.bt_in_range = in_range
      if changed:
        self.output()

      if self.bt_in_range:
        await asyncio.sleep(5)
      else:
        await asyncio.sleep(2)

  def output(self):
    print('[output]', self.enum, self.mute_speakers, self.automute)
    data = []

    # speakers
    icon_normal = choose_icon(icons_speaker, 0, 100, self.volume_speakers)
    match [self.enum, self.mute_speakers, self.automute]:
      case [states.BLUETOOTH, True, True]: icon = icon_normal
      case [_, True, _]: icon = icon_speaker_muted
      case _: icon = icon_normal
    match [self.enum, self.mute_speakers, self.automute]:
      case [states.BLUETOOTH, _, _]: color = 'background'
      case [_, _, True]: color = 'yellow'
      case _: color = 'blue'
    data.append(sc(color, icon))

    # percentage
    volume = self.volume_speakers if self.enum != states.BLUETOOTH else self.volume_bluetooth
    data.append(sc('foreground', f'{volume}%'))

    # bluetooth
    if self.bt_in_range:
      color = 'blue' if self.enum == states.BLUETOOTH else 'background'
      icon = icon_earbuds if self.mute_bluetooth == False else icon_earbuds_muted
      data.append(sc(color, icon))

    self.update(' '.join(data))

  def increase_volume(self):
    if self.enum != states.BLUETOOTH:
      set_volume(SPEAKERS_SINK, self.volume_speakers + 5)
    else:
      set_volume(BLUETOOTH_SINK, self.volume_bluetooth + 5)

  def decrease_volume(self):
    if self.enum != states.BLUETOOTH:
      set_volume(SPEAKERS_SINK, max(self.volume_speakers - 5, 0))
    else:
      set_volume(BLUETOOTH_SINK, max(self.volume_bluetooth - 5, 0))

  def toggle_mute(self):
    if self.enum != states.BLUETOOTH:
      self.automute = False
      set_mute(SPEAKERS_SINK)
    else:
      set_mute(BLUETOOTH_SINK)

  async def process_cmd(self, cmd):
    match(cmd):
      case 'up':
        self.increase_volume()

      case 'down':
        self.decrease_volume()

      case 'left':
        self.toggle_mute()

      case 'middle':
        await self.switch_sink()
    self.refresh()
    self.output()

if __name__ == '__main__':
  a = Impl('audio', 'audio')
  a.run('') # pass empty string so that self.output() gets triggered
