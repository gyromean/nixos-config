#!/usr/bin/env python

import sys, os
from utility import set_color

icons_idle = ['󰁺', '󰁻', '󰁼', '󰁽', '󰁾', '󰁿', '󰂀', '󰂁', '󰂂', '󰁹']
icons_charging = ['󰢜', '󰂆', '󰂇', '󰂈', '󰢝', '󰂉', '󰢞', '󰂊', '󰂋', '󰂅']

path_base = sys.argv[1]

def is_charging():
  with open(os.path.join(path_base, 'status')) as f:
    return f.read() == 'Charging\n'

def energy_now():
  with open(os.path.join(path_base, 'energy_now')) as f:
    return int(f.read())

def energy_max():
  with open(os.path.join(path_base, 'energy_full')) as f:
    return int(f.read())

def main():
  charge = energy_now() / energy_max()
  percentage = int(100 * charge + .5)
  icon_index = min(int(10 * charge), 9)
  icon = icons_charging[icon_index] if is_charging() else icons_idle[icon_index]
  print(' ' + set_color('blue', icon) + set_color('foreground', f' {percentage}% '))

if __name__ == '__main__':
  main()
