#!/usr/bin/env bash
set -euo pipefail

config=${1:-}
case "$config" in
  laptop.js|desktop.js) ;;
  *)
    echo "usage: $0 {laptop.js|desktop.js}" >&2
    exit 2
    ;;
esac

unit=ags-bar.service
load_state=$(systemctl --user show "$unit" --property=LoadState --value 2>/dev/null || true)
if [[ -n "$load_state" && "$load_state" != "not-found" ]]; then
  systemctl --user stop "$unit" || true
  systemctl --user reset-failed "$unit" 2>/dev/null || true

  # The user manager survives compositor restarts. Wait for --collect to remove
  # the old transient unit so the replacement gets this session's environment.
  for _ in $(seq 1 50); do
    load_state=$(systemctl --user show "$unit" --property=LoadState --value 2>/dev/null || true)
    if [[ -z "$load_state" || "$load_state" == "not-found" ]]; then
      break
    fi
    sleep 0.1
  done

  if [[ -n "$load_state" && "$load_state" != "not-found" ]]; then
    echo "failed to unload stale $unit" >&2
    exit 1
  fi
fi

exec systemd-run --user --quiet --collect \
  --unit="$unit" \
  --property=StartLimitIntervalSec=30s \
  --property=StartLimitBurst=5 \
  --property=Restart=on-failure \
  --property=RestartSec=1s \
  --property=KillMode=mixed \
  --property=SuccessExitStatus=143 \
  --property=TimeoutStopSec=3s \
  /run/current-system/sw/bin/bash "$HOME/.config/ags/run.sh" "$config"
