#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
CMD=${1-}
[[ $CMD ]] || { echo "Usage: $0 <backup|restore> <paths...>"; exit 1; }
shift
RETENTION=${RETENTION-7}
DEST_ROOT=${DEST_ROOT-/backup}
STAMP=$(date +%Y%m%d_%H%M%S)
TARGET="$DEST_ROOT/$STAMP"
LOCK="/tmp/backup_restore.lock"

exec 9>"$LOCK"
flock -n 9 || { echo "Another backup/restore is running"; exit 1; }

mkdir -p "$DEST_ROOT"

backup() {
  mkdir -p "$TARGET"
  for p in "$@"; do
    [[ -e "$p" ]] || { echo "Skip missing: $p"; continue; }
    base=$(basename "$p")
    tar -cpf - "$p" | gzip -c > "$TARGET/${base}.tar.gz"
  done
  echo "$STAMP" > "$TARGET/.done"
  # Retention
  ls -1dt "$DEST_ROOT"/*/ 2>/dev/null | tail -n +$((RETENTION+1)) | xargs -r rm -rf
  echo "Backup done at $TARGET"
}

restore() {
  local path="$1"; shift || true
  latest=$(ls -1dt "$DEST_ROOT"/*/ 2>/dev/null | head -n1)
  [[ -d "$latest" ]] || { echo "No backups found"; exit 1; }
  fname="$latest/$(basename "$path").tar.gz"
  [[ -f "$fname" ]] || { echo "No archive for $path in $latest"; exit 1; }
  tar -xpf "$fname" -C /
  echo "Restored $(basename "$path") from $latest"
}

case "$CMD" in
  backup) backup "$@" ;;
  restore) [[ ${1-} ]] || { echo "Specify path to restore"; exit 1; }; restore "$1" ;;
  *) echo "Invalid command: $CMD"; exit 1 ;;
esac