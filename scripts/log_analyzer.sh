#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
[[ ${1-} && ${2-} ]] || { echo "Usage: $0 <log_file> <report_dir>"; exit 1; }
LOG_FILE="$1"
REPORT_DIR="$2"
DATE=$(date +%F)
OUT="$REPORT_DIR/error_report_$DATE.txt"
mkdir -p "$REPORT_DIR"

[[ -f "$LOG_FILE" ]] || { echo "Log not found: $LOG_FILE"; exit 1; }

echo "===== Error Report for $DATE =====" > "$OUT"
echo "Source: $LOG_FILE" >> "$OUT"

grep -E "ERROR|WARN" "$LOG_FILE" | awk '{count[$0]++} END {for (l in count) print count[l] "\t" l}' \
  | sort -nr | head -n 50 >> "$OUT"

echo "\nSummary counts:" >> "$OUT"
printf "ERROR: %s\n" "$(grep -c "ERROR" "$LOG_FILE" || echo 0)" >> "$OUT"
printf "WARN : %s\n" "$(grep -c "WARN" "$LOG_FILE" || echo 0)" >> "$OUT"

echo "Report saved: $OUT"