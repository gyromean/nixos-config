#!/usr/bin/env python

colors = {
  'background': '#ff4c566a',
  'foreground': '#ffeceff4',
  'transparent': '#00000000',
  'blue': '#ff88C0D0',
  'red': '#ffbf616a',
  'yellow': '#ffebcb8b',
  'light-blue': '#1f88c0d0',
}

def set_color(color, data):
  return f'%{{F{colors[color]}}}' + data + '%{F-}'

def set_background(color, data):
  return f'%{{B{colors[color]}}}' + data + '%{B-}'

def set_underline(color, data):
  return f'%{{u{colors[color]}}}%{{+u}}' + data + '%{-u}'

def distribute_icons(steps, icons):
  ret = [None for _ in range(steps)]
  i_ret: int = 0
  i_icons = 0
  while i_ret < steps:
    if i_ret < (i_icons + 1) * steps / len(icons):
      ret[i_ret] = icons[i_icons]
      i_ret += 1
    else:
      i_icons += 1
  return ret
