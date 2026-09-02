#!/usr/bin/env bash
set -u

log="${XDG_RUNTIME_DIR:-/tmp}/hywoma-monitor-layout.log"

{
  printf '[%s] starting hywoma monitor layout\n' "$(date --iso-8601=seconds)"
  printf 'PATH=%s\n' "$PATH"
  command -v quickshell || true
  command -v hywoma || true
  quickshell -n -c hywoma-monitor-layout
  status=$?
  printf '[%s] quickshell exited with status %s\n' "$(date --iso-8601=seconds)" "$status"
} >>"$log" 2>&1
