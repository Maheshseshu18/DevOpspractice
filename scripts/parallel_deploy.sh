#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
[[ ${1-} && ${2-} && ${3-} ]] || { echo "Usage: $0 <hosts_file> <artifact> <remote_command>"; exit 1; }
HOSTS_FILE="$1"; ARTIFACT="$2"; REMOTE_CMD="$3"
SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5)

mapfile -t HOSTS < <(grep -Ev '^(#|$)' "$HOSTS_FILE")
[[ ${#HOSTS[@]} -gt 0 ]] || { echo "No hosts found"; exit 1; }

run_host() {
  local h="$1"; set -e
  scp "${SSH_OPTS[@]}" "$ARTIFACT" "$h:/tmp/" >/dev/null
  ssh "${SSH_OPTS[@]}" "$h" "tar -xf /tmp/$(basename "$ARTIFACT") -C /tmp || true; $REMOTE_CMD"
  echo "$h: OK"
}

pids=()
for h in "${HOSTS[@]}"; do
  ( run_host "$h" ) & pids+=("$!")
  # limit concurrency to 10
  [[ $(jobs -rp | wc -l) -ge 10 ]] && wait -n
 done
wait

echo "Deployment finished."