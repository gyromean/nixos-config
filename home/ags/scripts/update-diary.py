#!/usr/bin/env python

import sys, datetime, subprocess, os

TMP_FNAME = '/tmp/ags-tmp-diary'

weekday_to_name = ['po', 'ut', 'st', 'ct', 'pa', 'so', 'ne']

day, month, year, days_to_add = map(int, sys.argv[1:])

date = datetime.date(year, month, day)
delta = datetime.timedelta(days=1)

with open('/home/pavel/sync/denik.txt', 'a') as diaryf:
  for i in range(days_to_add):
    date += delta
    prefix = f'{weekday_to_name[date.weekday()]} {date.day:02}.{date.month:02}.{date.year} - '
    subprocess.run(['vim', f'+norm A{prefix}', '+startinsert!', TMP_FNAME])

    try:
      with open(TMP_FNAME) as tmpf:
        content = tmpf.read()
      if not content.startswith(prefix) or content.strip('\n') == prefix: # changed beginning or no change at all
        os.remove(TMP_FNAME)
        break
    except FileNotFoundError:
      break

    diaryf.write(content)
    diaryf.flush()

    os.remove(TMP_FNAME)
