#!/usr/bin/env python

# veci pro audio:
# TODO: misto pactl pouzivat neco pro pipewire (ted tam jeste bezi nejakej pipewire-pulse, mozna to dela preklad or something)
# TODO: asi ten sink mutnout jeste nez se prepnu na ten druhej
# TODO: jeste zkopirovat ty TODO z headphones.sh
# TODO: nekdy ten `bluetoothctl connect 00:C5:85:68:86:3E` timeoutne, tak v tom pripade ho asi pustit vickrat (retcode bude nenulovej)
# TODO: ty pactl ids (to cislo kdyz dam pactl list short sinks si vzdycky nechat vypsat kdyz budu davat mute (a nebo mozna to delat rovnout pres to jmeno (alsa_output.pci-0000_0b_00.4.analog-stereo a bluez_output.00_C5_85_68_86_3E.1)))
# TODO: kdyz mam pripojeny airpody a modifikuju hlasitost z nich ta se mi to nepropisuje do polybaru protoze to samozrejme nezapisuje do toho socketu, takze to by chtelo nejak prebindovat
# BUG: na laptopu kdyz primo dam sluchatka do jacku, tak se mi treba unmutne audio, ale tenhle polybar modul to neukaze (takze asi potrebuju nejak odposlechnout event ze se zmenil sink nebo mute nebo tak neco (az se mi updatne verze wireplumberu, nemohl bych primo z ty lua sem nejak poslat ping (treba pres ten socket?)))
# NOTE: prikazy: `bluetoothctl connect 00:C5:85:68:86:3E` na pripojeni, `pactl set-default-sink bluez_output.00_C5_85_68_86_3E.1` na prepnuti default sinku

# ikony
'''
󰕿 󰖀 󰕾  - SPEAKER_ACTIVE
󰸈      - SPEAKER_MUTED / SPEAKER_CONFIRM
󰋋 󰟎    -
󱡏 󱡐    -


󰸴

..|.
'''

# keywordy na nerdfonts
'''
speaker
volume
audio
headphones <-- normalni sluchatka (overheady)
earbuds <-- dost podobny airpodu
'''

# programy
'''
pactl
pavucontrol

pw-cli # pro dumpovani v JSONu pouzit pw-dump
qpwgraph
'''

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
  while True:
    print('trying to get volume')
    try:
      comp_proc = subprocess.run(['wpctl', 'get-volume', str(sink)], capture_output=True)
      output = comp_proc.stdout.decode().strip()
      volume = int(output.split(' ')[1].replace('.', ''))
      print('success')
      return volume
    except IndexError:
      print('IndexError, retrying...')
      pass

# state is '1' for mute, '0' for unmute, or 'toggle'
def set_mute(state='toggle', sink='@DEFAULT_SINK@'):
  subprocess.run(['wpctl', 'set-mute', str(sink), str(state)])

# returns True if muted, False otherwise
def get_mute(sink='@DEFAULT_SINK@'):
  comp_proc = subprocess.run(['pactl', 'get-sink-mute', str(sink)], capture_output=True)
  output = comp_proc.stdout.decode().strip()
  mute_str = output.split(': ')[1]
  return False if mute_str == 'no' else True

def wait_wireplumber_running(sink='@DEFAULT_SINK@'):
  while True:
    comp_proc = subprocess.run(['wpctl', 'get-volume', str(sink)], capture_output=True)
    output = comp_proc.stdout.decode().strip()
    if output != '':
      return

class Impl(PolybarIPC):
  def __init__(self, headphones_mac, *args, **kwargs):
    super().__init__(*args, **kwargs)
    wait_wireplumber_running()
    self.headphones_mac = headphones_mac
    self.volume = get_volume() // 5 * 5
    self.mute = get_mute()
    # self.bt_connected = self.is_bluetooth_connected() # NOTE: for future use
    self.bt_connected = False

  def is_bluetooth_connected(self):
    comp_proc = subprocess.run(['bluetoothctl', 'info', self.headphones_mac], capture_output=True) # BUG: this call does not finish, happens after switching to a new nix channel (maybe it is because bluetooth is not running in the first place or something like that)
    output = comp_proc.stdout.decode()
    connected_lines = list(filter(lambda line: line.strip().startswith('Connected'), output.splitlines()))
    is_connected = len(connected_lines) and connected_lines[0].endswith('yes')
    return bool(is_connected)

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
