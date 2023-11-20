#!/usr/bin/env bash

# TODO - ty headphones musi byt paired, ale untrusted

# TODO - zmint na IPC (jedna instance bude furt bezet na pozadi a posilat polybaru vypis pres IPC, druha se zavola jen na toggle (a pouzije ten blink command))
# TODO - dodelat to stopnuti audia kdyz se zmeni sink
# TODO - odstranit ostatni vypisy (ale vlastne to pak nevadi kdyz se to predela na IPC)
# TODO - mozna by to slo pridat do toho volume modulu ze bych si ho udelal sam a prepnuti mezi sluchatkama a reproduktorem by se delalo pres rightclick
# TODO - kdyz nehraje hudba tak se ten sink switch myslim neprojevi
# TODO - automaticky enablovat bluetooth pres https://unix.stackexchange.com/questions/676972/how-to-solve-bluez-connection-attempts-failing-with-br-connection-adapter-not

headphones_mac=00:C5:85:68:86:3E
headphones_sink=00_C5_85_68_86_3E

headphones_selected()
{
  pactl get-default-sink | fgrep bluez
  return $?
}

display_connected() { echo "Yay"; }
display_disconnected() { echo "Nah"; }
display_error() { echo "Chyba"; }
display_state()
{
  if headphones_selected; then
    display_connected
  else
    display_disconnected
  fi
}

blink()
{
  display_error
  sleep 1
  display_state
}

get_headphones_sink()
{
  pactl list short sinks | cut -f2 | fgrep bluez | head -n1
}

get_physical_sink()
{
  pactl list short sinks | cut -f2 | fgrep -v bluez | head -n1
}

connect()
{
  if bluetoothctl connect "$headphones_mac"; then
    headphones_sink_name=$(get_headphones_sink)
    while [ -z "$headphones_sink_name" ]; do
      sleep .1
      headphones_sink_name=$(get_headphones_sink)
    done
    pactl set-default-sink $(get_headphones_sink)
  else
    blink # useless, it won't get displayed in polybar
  fi
}

disconnect()
{
  pactl set-default-sink $(get_physical_sink)
}

if [ "$1" == "toggle" ]; then
  if headphones_selected; then
    disconnect
  else
    connect
  fi
  exit
fi

display_state

curr_sink=$(pactl get-default-sink)

pactl subscribe | fgrep --line-buffered sink | while read -r line; do # tohle se myslim protne i kdyz se zmeni volume, takze by merge s volume modulem mohl byt docela straight forward TODO - odstranit tenhle comment
  next_sink=$(pactl get-default-sink)
  # if [ "$curr_sink" != "$next_sink" ]; then
  #   echo zmena
  #   playerctl pause
  # fi
  display_state
  curr_sink="$next_sink"
done
