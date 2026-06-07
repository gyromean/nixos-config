#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_RUNTIME_DIR:-/tmp}/handy-dictation"
state_file="$state_dir/state"
ags_socket="/tmp/ags-bar.sock"

send_ags() {
  if [ -S "$ags_socket" ]; then
    printf 'dictation %s\n' "$1" | nc -Uw0 "$ags_socket" || true
  fi
}

mkdir -p "$state_dir"

state="idle"
if [ -f "$state_file" ]; then
  state="$(cat "$state_file")"
fi

if [ "$state" = "listening" ]; then
  printf 'idle\n' > "$state_file"
  send_ags done
else
  printf 'listening\n' > "$state_file"
  send_ags listening
fi

handy --toggle-transcription
