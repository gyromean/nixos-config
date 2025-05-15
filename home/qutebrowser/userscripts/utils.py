import subprocess, os

__all__ = ['run_cmd', 'send', 'msg']

fifo_fname = os.environ.get('QUTE_FIFO')
fifo_file = open(fifo_fname, 'a')

def run_cmd(args, strip=True, timeout=None):
  if isinstance(args, str):
    args = args.split()
  else:
    args = list(map(str, args))
  comp_proc = subprocess.run(args, capture_output=True, timeout=timeout)
  output = comp_proc.stdout.decode()
  if strip:
    output = output.strip()
  return output

def send(cmd):
  if isinstance(cmd, list):
    cmd = ' '.join(map(str, cmd))
  print(cmd, file=fifo_file)

def msg(message, quote="'"):
  send(['message-info', ''.join([quote, str(message), quote])])
