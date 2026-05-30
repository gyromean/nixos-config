#!/usr/bin/env python

import json
import subprocess
import sys

HYWOMA = 'hywoma'


def rofi_query(options, use_nums=False):
  by_option = {}
  rofi_options = []
  for i, option in enumerate(options):
    rofi_option = f'{i + 1}) {option}' if use_nums else option
    # Rofi strips/normalizes user selections in ways that can remove the visual active prefix. Store
    # both the exact and stripped forms so selecting an already-prefixed row still resolves.
    by_option[rofi_option] = (i, option)
    by_option[rofi_option.strip()] = (i, option)
    rofi_options.append(rofi_option)

  proc = subprocess.run(['rofi', '-i', '-dmenu'], capture_output=True, text=True, input='\n'.join(rofi_options))
  choice = proc.stdout.strip()
  if choice == '':
    return (-1, '')
  return by_option.get(choice, (-2, choice))


def rofi_notification(data):
  subprocess.run(['rofi', '-e', data])


def hywoma(*args):
  proc = subprocess.run([HYWOMA, *map(str, args)], capture_output=True, text=True)
  if proc.returncode != 0:
    raise RuntimeError(proc.stderr.strip() or f'hywoma {args[0]} failed')
  return proc.stdout


def get_status():
  return json.loads(hywoma('status'))


def group_names(status):
  return {group['name'] for group in status['state']['groups']}


def choose_group(status, include_active=True):
  active_group = status['state']['active_group']
  previous_group = status['state'].get('previous_group')
  groups = list(status['state']['groups'])
  if include_active and previous_group is not None:
    # Put the previous group first for the quick selector. With two groups, Win+P Enter becomes a
    # fast toggle because hywoma updates previous_group on every real switch.
    groups.sort(key=lambda group: (group['id'] != previous_group, group['id']))

  options = []
  by_option = {}
  for group in groups:
    if not include_active and group['id'] == active_group:
      continue
    prefix = '* ' if group['id'] == active_group else '  '
    option = f'{prefix}{group["name"]}'
    options.append(option)
    by_option[option] = group
    by_option[option.strip()] = group
    by_option[group['name']] = group

  proc = subprocess.run(['rofi', '-i', '-dmenu'], capture_output=True, text=True, input='\n'.join(options))
  choice = proc.stdout.strip()
  if choice == '':
    return None
  return by_option.get(choice)


def group_has_present_workspaces(status, group_id):
  # Deletion should be blocked by workspaces that currently exist in Hyprland, not by persisted
  # mappings for empty workspaces. hywoma exposes present_workspace_ids for exactly this distinction.
  by_internal_id = {
    workspace['internal_id']: workspace
    for workspace in status['state']['workspaces']
  }
  for workspace_id in status.get('present_workspace_ids', []):
    workspace = by_internal_id.get(workspace_id)
    if workspace is not None and workspace['group'] == group_id:
      return True
  return False


def select_group(status):
  group = choose_group(status)
  if group is None:
    return
  hywoma('switch_group', group['id'])


def new_group(status):
  _, name = rofi_query([])
  name = name.strip()
  if name == '':
    return
  if name in group_names(status):
    rofi_notification(f'Group {name} already exists')
    return
  hywoma('create_group', name)


def delete_group(status):
  group = choose_group(status, include_active=False)
  if group is None:
    return
  if group_has_present_workspaces(status, group['id']):
    rofi_notification(f'Group {group["name"]} contains non-empty workspaces')
    return
  hywoma('delete_group', group['id'])


def move_containers(status):
  group = choose_group(status, include_active=False)
  if group is None:
    return
  # This moves only the focused container, matching Hyprland's movetoworkspacesilent behavior. The
  # menu text says "containers" because it mirrors the old workflow wording.
  hywoma('move_to_group', group['id'])


def rename_group(status):
  active_group_id = status['state']['active_group']
  active_group = next(group for group in status['state']['groups'] if group['id'] == active_group_id)
  _, name = rofi_query([])
  name = name.strip()
  if name == '' or name == active_group['name']:
    return
  if name in group_names(status):
    rofi_notification(f'Group {name} already exists')
    return
  hywoma('rename_group', active_group_id, name)


def show_menu(cmd=None):
  try:
    status = get_status()
    if cmd is None:
      cmd = rofi_query([
        '󱄄 New group',
        '󰶐 Delete group',
        '󰨇 Move containers to different group',
        '󱋆 Rename group',
        '󰍺 Select group',
      ], True)

    match cmd:
      case (0, _):
        new_group(status)
      case (1, _):
        delete_group(status)
      case (2, _):
        move_containers(status)
      case (3, _):
        rename_group(status)
      case (4, _):
        select_group(status)
      case (-1, _):
        return
      case _:
        rofi_notification('Unknown option')
  except Exception as err:
    rofi_notification(f'Cannot manage hywoma groups: {err}')


def main():
  match sys.argv:
    case [_, 'select-group']:
      show_menu((4, None))
    case [_]:
      show_menu()
    case _:
      rofi_notification('Unknown hywoma-groups command')


if __name__ == '__main__':
  main()
