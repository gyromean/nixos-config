#!/usr/bin/env bash
set -u

config=${1:?missing AGS config filename}
ags=$(command -v ags1)

"$ags" -c "$HOME/.config/ags/$config" -b bar &
pid=$!

stop() {
  trap - TERM INT
  "$ags" --quit --bus-name bar >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do
    if ! kill -0 "$pid" 2>/dev/null; then
      wait "$pid" 2>/dev/null || true
      exit 143
    fi
    sleep 0.1
  done
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  exit 143
}
trap stop TERM INT

for _ in $(seq 1 20); do
  if ! kill -0 "$pid" 2>/dev/null; then
    wait "$pid"
    exit $?
  fi
  if hyprctl layers -j \
    | jq -e --argjson pid "$pid" \
      '[.. | objects | .pid? // empty] | any(. == $pid)' >/dev/null; then
    wait "$pid"
    exit $?
  fi
  sleep 0.25
done

echo "AGS process $pid did not create a layer surface" >&2
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
exit 1
