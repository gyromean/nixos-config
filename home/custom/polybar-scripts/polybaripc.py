#!/usr/bin/env python

import asyncio, subprocess
from utility import log_print

class PolybarIPC:
  def __init__(self, module_name, socket_identifier=None, polybar_pid=None):
    self.module_name = module_name
    self.socket_identifier = socket_identifier
    self.polybar_pid = polybar_pid

    self.tasks_to_create = []
    self.use_socket = socket_identifier is not None
    if self.use_socket:
      self.socket_name = f'/tmp/polybar_{socket_identifier}.sock'
      self.tasks_to_create.append(asyncio.start_unix_server(self._socket_reader, self.socket_name))

    self.q = asyncio.Queue()
    self.is_running = False

  # --- PRIVATE METHODS ---
  async def _socket_reader(self, reader, writer):
    while True:
      cmd = await reader.readline()
      cmd = cmd.decode().rstrip('\n')
      if len(cmd) == 0:
        return
      await self.q.put(cmd)

  async def _run(self, cmd):
    if cmd:
      await self.q.put(cmd)
    for task in self.tasks_to_create:
      asyncio.create_task(task)
    while True:
      cmd = await self.q.get()
      log_print(f"Processing cmd '{cmd}'")
      await self.process_cmd(cmd)

  # --- PUBLIC METHODS ---
  def create_task(self, coro, delay_s=None):
    if delay_s is not None:
      _coro = coro
      async def wrapper():
        nonlocal _coro
        await asyncio.sleep(delay_s)
        await _coro
      coro = wrapper()
    if not self.is_running: # enque if not running already; otherwise create now
      self.tasks_to_create.append(coro)
    else:
      return asyncio.create_task(coro) # TODO: figure out how to cancel existing task (I can return the task here, but if it was task with delay_s set, it will throw message that the original coro was not awaited)

  def run(self, cmd=None):
    self.is_running = True
    asyncio.run(self._run(cmd))

  async def push_cmd(self, cmd):
    await self.q.put(cmd)

  def update(self, data, use_spaces=True):
    if use_spaces: data = ' ' + data + ' '
    payload = ['polybar-msg']
    if self.polybar_pid: payload.extend(['-p', self.polybar_pid])
    payload.extend(['action', self.module_name])
    payload.extend(['send', data])
    subprocess.run(list(map(str, payload)))
    log_print(f"Updating polybar '{data}'")

  # --- TO IMPLEMENT IN CHILD ---
  # async def process_cmd(self, cmd) -> None

  @staticmethod
  def cancellable(func):
    async def ret_func(*args, **kwargs):
      try:
        await func(*args, **kwargs)
      except asyncio.exceptions.CancelledError:
        pass
    return ret_func
