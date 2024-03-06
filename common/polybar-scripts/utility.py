#!/usr/bin/env python

from datetime import datetime
from math import floor

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

# for example, for values icons = 'abcd', start = 0, end = 9 and request = 0..9 and prefer_periodic set to:
# True, algorithm produces  aaa bb ccc dd
# False, algorithm produces aaa bb cc ddd (prefers symmetric)
# None, algorithm sets prefer_periodic to True if the number of icons is even, False if it's odd
def choose_icon(icons, start, end, request, prefer_periodic=True): # TODO: odstranit debug parametr
  if request <= start:
    return icons[0]
  if request >= end:
    return icons[-1]
  request -= start
  interval_size = end - start
  if prefer_periodic == None:
    prefer_periodic = len(icons) % 2 == 0
  if prefer_periodic:
    interval_size += 1
  index = floor(request / (interval_size / len(icons)))
  return icons[index]

def log_print(data):
  print(f'[{datetime.now()}] {data}')
