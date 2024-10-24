#!/usr/bin/env python

import sys
import subprocess
import json
from utils import pack_to_id, unpack_id

def run_cmd(args, timeout=None):
  comp_proc = subprocess.run(args, capture_output=True, timeout=timeout)
  return comp_proc.stdout.decode()

def _workspace(cmd):
  workspace = sys.argv[2]
  print(f'{workspace = }')
  active_workspace_id = json.loads(run_cmd(['hyprctl', '-j', 'activeworkspace']))['id']
  print(f'{active_workspace_id = }')
  w, m, g = unpack_id(active_workspace_id)
  print(f'{(w, m, g) = }')
  w = int(workspace)
  print(f'{w = }')
  target_workspace_id = pack_to_id(w, m, g)
  print(f'{target_workspace_id = }')
  run_cmd(['hyprctl', 'dispatch', cmd, f'{target_workspace_id}'])

def _monitor(cmd):
  monitor_id = {
    'u': 1,
    'i': 2,
    'o': 3,
  }[sys.argv[2]]
  monitors = json.loads(run_cmd(['hyprctl', '-j', 'monitors']))
  for monitor in monitors:
    id_ = monitor['activeWorkspace']['id']
    print(f'{id_ = }')
    _, m, _ = unpack_id(id_)
    print(f'{m = }')
    print(f'{monitor_id = }')
    if m == monitor_id:
      run_cmd(['hyprctl', 'dispatch', cmd, f'{id_}'])
      return

def select_workspace():
  _workspace('workspace')

def move_to_workspace():
  _workspace('movetoworkspacesilent')

def select_monitor():
  _monitor('workspace')
  pass

def move_to_monitor():
  _monitor('movetoworkspacesilent')
  pass

def swap():
  # TODO:
  pass

if __name__ == '__main__':
  match sys.argv[1]:
    case 'select_workspace':
      select_workspace()
    case 'move_to_workspace':
      move_to_workspace()
    case 'select_monitor':
      select_monitor()
    case 'move_to_monitor':
      move_to_monitor()
    case 'swap':
      swap()
