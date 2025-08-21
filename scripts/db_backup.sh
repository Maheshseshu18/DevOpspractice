#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
DB_TYPE=${DB_TYPE-mysql}   # mysql|postgres
DB=${DB-}
DB_USER=${DB_USER-}
DB_PASS=${DB_PASS-}
RETENTION=${RETENTION-7}
DEST=${DEST-/var/backups/db}
STAMP=$(date +%F_%H%M%S)
mkdir -p "$DEST"

[[ $DB && $DB_USER ]] || { echo "Set DB, DB_USER and optionally DB_PASS"; exit 1; }

OUT="$DEST/${DB}_${STAMP}.sql.gz"

case "$DB_TYPE" in
  mysql)
    export MYSQL_PWD="$DB_PASS"
    mysqldump --single-transaction --routines --triggers -u "$DB_USER" "$DB" | gzip -c > "$OUT"
    ;;
  postgres)
    export PGPASSWORD="$DB_PASS"
    pg_dump -U "$DB_USER" "$DB" | gzip -c > "$OUT"
    ;;
  *) echo "Unknown DB_TYPE: $DB_TYPE"; exit 1 ;;
esac

# Quick sanity check: file not empty
[[ -s "$OUT" ]] || { echo "Backup file is empty!"; exit 1; }

# Retention
ls -1t "$DEST"/*.sql.gz 2>/dev/null | tail -n +$((RETENTION+1)) | xargs -r rm -f

echo "Backup saved: $OUT"