#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
THRESHOLD=${1-80}
shift || true
CLEAN_DIRS=("${@:-/var/log /tmp}")
ALERT_EMAIL=${ALERT_EMAIL-admin@localhost}

usage() { echo "Usage: $0 <threshold_percent> [dir1 dir2 ...]"; }

percent_used() {
  df -P --output=pcent / | tail -1 | tr -dc '0-9'
}

PU=$(percent_used)
if (( PU >= THRESHOLD )); then
  echo "Disk / is $PU% full (>= $THRESHOLD%). Cleaning..." | mail -s "Disk Alert" "$ALERT_EMAIL" 2>/dev/null || true
  for d in "${CLEAN_DIRS[@]}"; do
    find "$d" -type f -name "*.log" -mtime +7 -exec gzip -f {} + 2>/dev/null || true
    find "$d" -type f -name "*.gz" -mtime +30 -delete 2>/dev/null || true
    find "$d" -type f -mtime +45 -delete 2>/dev/null || true
  done
  journalctl --vacuum-time=7d >/dev/null 2>&1 || true
fi

echo "Current usage: $PU%"
