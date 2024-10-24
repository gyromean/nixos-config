#!/usr/bin/env python

# workspace indexed from 1
# monitor indexed from 1
# group indexed from 0

def pack_to_id(workspace, monitor=1, group=0):
  workspace -= 1
  monitor -= 1
  id_ = workspace + 10 * monitor + 100 * group
  id_ += 1
  assert id_ > 0
  return id_

def unpack_id(id_):
  assert id_ > 0
  id_ -= 1
  workspace = id_ % 10 + 1
  id_ //= 10
  monitor = id_ % 10 + 1
  id_ //= 10
  group = id_ % 10
  return (workspace, monitor, group)
