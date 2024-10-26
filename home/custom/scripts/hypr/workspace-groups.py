#!/usr/bin/env python

import subprocess, json, time, os, itertools, sys
from utils import pack_to_id, unpack_id, send_socket

def refresh_ags_bar():
  active_group = get_active_group()
  groups = get_groups()
  for name, num in groups.items():
    if num == active_group:
      j = json.dumps([int(active_group), name, len(groups)])
      send_socket('workspace-group', j)

def rofi_query(options, use_nums=False):
  options_dict = {}
  options_rofi = []
  for i, option in enumerate(options):
    if use_nums:
      option_rofi = f'{i + 1}) {option.strip()}'
    else:
      option_rofi = option.strip()
    options_dict[option_rofi] = (i, option)
    options_rofi.append(option_rofi)
  proc = subprocess.run(['rofi', '-i', '-dmenu'], capture_output=True, input='\n'.join(options_rofi).encode())
  choice = proc.stdout.strip().decode()
  if choice == '':
    return (-1, 'aborted')
  return options_dict.get(choice, (-2, choice))

def rofi_notification(data):
  subprocess.run(['rofi', '-e', data])

def get_active_group():
  try:
    return open('/tmp/hypr-workspace-groups-active').read().strip()
  except FileNotFoundError:
    return '0'

def save_active_group(active_group_num):
  with open('/tmp/hypr-workspace-groups-active', 'w') as f:
    f.write(active_group_num)

def get_previous_group():
  try:
    return open('/tmp/hypr-workspace-groups-previous').read().strip()
  except FileNotFoundError:
    return None

def save_previous_group(previous_group_num):
  with open('/tmp/hypr-workspace-groups-previous', 'w') as f:
    f.write(previous_group_num)

def get_displayed_workspaces():
  displayed_workspaces = json.loads(subprocess.run(['hyprctl', '-j', 'monitors'], capture_output=True).stdout)
  ret = []
  for displayed_workspace in displayed_workspaces:
    name = displayed_workspace['activeWorkspace']['id']
    ret.append(name)
  return ret

def get_selected_workspace():
  return json.loads(subprocess.getoutput("hyprctl activeworkspace -j"))['id']

def get_stashed_group(active_group_num, delete=True): # automatically deletes stash file
  active_group_num = int(active_group_num)
  fname = f'/tmp/hypr-workspace-groups-stashed-{active_group_num}'
  try:
    with open(fname) as f:
      ret = json.load(f)
    if delete:
      os.remove(fname)
    return ret
  except FileNotFoundError:
    ret = []
    for i in range(1, len(get_displayed_workspaces()) + 1):
      ret.append(pack_to_id(1, i, active_group_num))
    ret = ret[:len(ret) // 2] + list(reversed(ret[len(ret) // 2:])) # make middle screen last one, thus the one with cursor
    return ret

def save_stashed_group(active_group_num): # last one is currently active
  fname = f'/tmp/hypr-workspace-groups-stashed-{active_group_num}'
  displayed_workspaces = get_displayed_workspaces()
  selected_workspace = get_selected_workspace()
  ret = []
  for displayed_workspace in displayed_workspaces:
    if displayed_workspace != selected_workspace:
      ret.append(displayed_workspace)
  ret.append(selected_workspace)
  with open(fname, 'w') as f:
    json.dump(ret, f)
  return ret

def display_workspaces(next_workspaces):
  displayed_workspaces = get_displayed_workspaces()
  display_dict = {}
  for displayed_workspace in displayed_workspaces:
    _, display, _ = unpack_id(displayed_workspace)
    display_dict[display] = displayed_workspace
  for next_workspace in next_workspaces:
    _, display, _ = unpack_id(next_workspace)
    curr_workspace = display_dict[display]
    display_dict[display] = next_workspace
    subprocess.run(['hyprctl', '--batch', f'dispatch workspace {curr_workspace} ; dispatch workspace {next_workspace}'])

def get_groups():
  try:
    return json.load(open('/tmp/hypr-workspace-groups-info'))
  except FileNotFoundError:
    return {'Main':'0'}

def save_groups(groups):
  with open('/tmp/hypr-workspace-groups-info', 'w') as f:
    json.dump(groups, f)

def switch_to(group_num):
  curr_group_num = get_active_group()
  if group_num == curr_group_num:
    return
  save_previous_group(curr_group_num)
  save_stashed_group(curr_group_num)

  save_active_group(group_num)
  workspaces = get_stashed_group(group_num)

  display_workspaces(workspaces)

# --------------------- UI ---------------------

def cmd_select_group(groups):
  groups_list = list(groups)
  if (previous_group := get_previous_group()):
    for name, num in groups.items():
      if num == previous_group:
        groups_list.remove(name)
        groups_list.insert(0, name)
        break

  code, group_name = rofi_query(groups_list)
  if code == -1:
    return
  if code == -2:
    rofi_notification(f'Unknown group {group_name}')
    return
  selected_group = groups[group_name]
  switch_to(selected_group)

def cmd_new_group(groups):
  code, group_name = rofi_query([])
  if code == -1:
    return
  if group_name in groups:
    rofi_notification(f'Group {group_name} already exists')
    return
  for group_num in itertools.count():
    if str(group_num) not in groups.values():
      break
  group_num = str(group_num)
  groups[group_name] = group_num
  save_groups(groups)
  switch_to(group_num)

# TODO: tady pokracovat
def cmd_delete_group(groups):
  groups_list = []
  active_group = get_active_group()
  for name, num in groups.items():
    if num != active_group:
      groups_list.append(name)
  code, group_name = rofi_query(groups_list)
  if code == -1:
    return
  if code == -2:
    rofi_notification(f'Unknown group {group_name}')
    return
  group_num = int(groups[group_name])

  for client in json.loads(subprocess.getoutput('hyprctl -j clients')):
    _, _, g = unpack_id(client['workspace']['id'])
    if g == group_num:
      rofi_notification(f'Group {group_name} contains non empty workspaces, cannot delete')
      return

  # if deleting previously active group, delete /tmp/hypr-workspace-groups-previous:
  if get_previous_group() == group_num:
    os.remove('/tmp/hypr-workspace-groups-previous')
  # delete record from /tmp/hypr-workspace-groups-info
  del groups[group_name]
  save_groups(groups)
  # delete /tmp/hypr-workspace-groups-stashed-...:
  get_stashed_group(group_num)

def cmd_move_containers(groups): # move to active monitor in selected destination group is not possible, because the associated workspace doesn't have to exist (if it was empty, it perished when deselected) -> it is possible that the destination workspace will be created, and normally it is created on the same monitor. That's why this function moves containers to different group, but on the same monitor and doesn't move them to the last selected monitor in said group
  groups_list = []
  active_group = get_active_group()
  for name, num in groups.items():
    if num != active_group:
      groups_list.append(name)
  code, group_name = rofi_query(groups_list)
  if code == -1:
    return
  if code == -2:
    rofi_notification(f'Unknown group {group_name}')
    return
  group_num = groups[group_name]
  destination_workspaces = get_stashed_group(group_num, False)
  _, display, _ = unpack_id(get_selected_workspace())
  for destination_workspace in destination_workspaces:
    if unpack_id(destination_workspace)[1] == display:
      subprocess.run(['hyprctl', 'dispatch', 'movetoworkspacesilent', str(destination_workspace)])
      return

def cmd_rename_group(groups):
  active_group = get_active_group()
  for group_name, num in groups.items():
    if num == active_group:
      break
  code, new_group_name = rofi_query([])
  if code == -1 or new_group_name == group_name:
    return
  if new_group_name in groups:
    rofi_notification(f'Group {new_group_name} already exists')
    return
  groups[new_group_name] = groups[group_name]
  del groups[group_name]
  save_groups(groups)

def show_menu(cmd=None):
  groups = get_groups()
  if cmd is None:
    cmd = rofi_query(['󱄄 New group', '󰶐 Delete group', '󰨇 Move containers to different group', '󱋆 Rename group', '󰍺 Select group'], True)
  match cmd:
    case (0, _): # new group
      cmd_new_group(groups)
    case (1, _): # delete group
      cmd_delete_group(groups)
    case (2, _): # move containers
      cmd_move_containers(groups)
    case (3, _): # rename group
      cmd_rename_group(groups)
    case (4, _): # select group
      cmd_select_group(groups)
    case (-1, _):
      return;
    case _:
      rofi_notification('Unknown option')
  refresh_ags_bar()

def main():
  match sys.argv:
    case [_, 'select-group']:
      show_menu((4, None))
    case _:
      show_menu()

if __name__ == '__main__':
  main()
