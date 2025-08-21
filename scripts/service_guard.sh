#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
SERVICES=("${@}")
[[ ${#SERVICES[@]} -gt 0 ]] || { echo "Usage: $0 <service1> [service2 ...]"; exit 1; }

SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL-}
ALERT_EMAIL=${ALERT_EMAIL-admin@localhost}
LOG_FILE="/var/log/service_guard.log"
mkdir -p "$(dirname "$LOG_FILE")"

notify() {
  local msg="$1"
  logger -t service_guard "$msg"
  echo "$(date -Is) $msg" | tee -a "$LOG_FILE"
  if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
    curl -s -X POST -H 'Content-type: application/json' --data "{\"text\":\"$msg\"}" "$SLACK_WEBHOOK_URL" >/dev/null || true
  else
    printf "%s\n" "$msg" | mail -s "[service_guard] alert" "$ALERT_EMAIL" 2>/dev/null || true
  fi
}

trap 'notify "Script interrupted"' INT TERM

for svc in "${SERVICES[@]}"; do
  if ! systemctl is-active --quiet "$svc"; then
    notify "Service $svc is down. Attempting restart..."
    if systemctl restart "$svc"; then
      sleep 2
      if systemctl is-active --quiet "$svc"; then
        notify "Service $svc restarted successfully."
      else
        notify "FAILED to restart $svc. Manual intervention required."
      fi
    else
      notify "Restart command failed for $svc."
    fi
  fi
 done