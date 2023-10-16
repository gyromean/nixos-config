#!/usr/bin/env python

import subprocess, sys
from i3ipc import Connection, Event
from utility import set_color, set_background, set_underline

monitor_id_map = {
  # 'DP-0': '1',
  # 'DP-4': '2',
  # 'DP-2': '3',
  name: str(i) for i, name in enumerate(sys.argv[3:], start=1)
}

polybar_pid = sys.argv[1]
monitor_id = monitor_id_map[sys.argv[2]]

def set_output_raw(data):
  print(f'setting output >{data}<')
  return subprocess.run(['polybar-msg', '-p', polybar_pid, 'action', 'i3', 'send', data]).returncode

def get_active_group():
  try:
    return open('/tmp/i3-workspace-groups-active').read().strip()
  except FileNotFoundError:
    return '0'

def on_workspace_event(i3, e):
  data = []
  focused_workspace_name = i3.get_tree().find_focused().workspace().name
  active_group = get_active_group()
  for workspace in i3.get_workspaces():
    name = workspace.name
    display_name, workspace_monitor, group = name.split(':')
    if workspace_monitor != monitor_id or group != active_group:
      continue
    formatted_name = set_color('foreground', f' {display_name} ')
    if name == focused_workspace_name:
      formatted_name = set_underline('blue', formatted_name)
      formatted_name = set_background('light-blue', formatted_name)
    data.append(formatted_name)

  set_output_raw(''.join(data))

i3 = Connection()
i3.on(Event.WORKSPACE, on_workspace_event)

on_workspace_event(i3, None)

i3.main()
