#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() { echo "Usage: $0 <users.csv>" >&2; exit 1; }
[[ ${1-} ]] || usage
CSV="$1"
LOG_DIR="/var/log/user_onboard"
LOG_FILE="$LOG_DIR/$(date +%F).log"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

trap 'echo "[ERROR] Interrupted or failed. See log: $LOG_FILE"' INT TERM ERR

echo "[INFO] Starting user onboarding from: $CSV"

if ! command -v chpasswd >/dev/null; then
  echo "[ERROR] chpasswd not found"; exit 1
fi

while IFS=, read -r username password group expiry_days || [[ -n "${username-}" ]]; do
  [[ -z "${username-}" || "$username" =~ ^# ]] && continue
  expiry_days=${expiry_days:-90}

  if ! getent group "$group" >/dev/null 2>&1; then
    echo "[INFO] Creating group: $group"
    groupadd "$group"
  fi

  if id "$username" >/dev/null 2>&1; then
    echo "[WARN] User $username already exists. Skipping add, updating password & expiry."
  else
    echo "[INFO] Creating user: $username (group: $group)"
    useradd -m -g "$group" -s /bin/bash "$username"
  fi

  echo "$username:$password" | chpasswd
  chage -M "$expiry_days" "$username"
  passwd -e "$username" >/dev/null 2>&1 || true
  echo "[OK] $username provisioned; password expires in $expiry_days days"
done < "$CSV"

echo "[DONE] User onboarding complete. Log: $LOG_FILE"
