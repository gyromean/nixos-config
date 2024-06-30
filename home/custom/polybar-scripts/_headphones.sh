#!/usr/bin/env bash

headphones_mac=00:C5:85:68:86:3E

headphones_connected()
{
  bluetoothctl devices Connected | fgrep "$headphones_mac" >/dev/null
  return $?
}

display_connected() { echo "YES"; }

display_disconnected() { echo "NO"; }

connect() { bluetoothctl connect "$headphones_mac"; }

disconnect() { bluetoothctl disconnect "$headphones_mac"; }

if [ "$1" == "toggle" ]; then
  if headphones_connected; then
    disconnect
  else
    connect
  fi
  exit
fi

if headphones_connected; then
  display_connected
else
  display_disconnected
fi

bluetoothctl | grep --line-buffered Device | while read -r line; do
  if echo "$line" | fgrep 'Connected: yes' >/dev/null; then
    display_connected
  fi
  if echo "$line" | fgrep 'Connected: no' >/dev/null; then
    display_disconnected
  fi
done
