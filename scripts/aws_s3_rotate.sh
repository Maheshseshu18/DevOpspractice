#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
BUCKET=${1-}; SRC_DIR=${2-}; DAYS=${3-30}
REGION=${AWS_REGION-ap-south-1}
[[ $BUCKET && $SRC_DIR ]] || { echo "Usage: $0 <bucket> <src_dir> [days]"; exit 1; }

if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Creating bucket s3://$BUCKET in $REGION"
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
fi

# Sync local logs
aws s3 sync "$SRC_DIR" "s3://$BUCKET/" --storage-class STANDARD_IA

# Delete objects older than N days (use lifecycle policy in prod)
cutoff=$(date -u -d "-$DAYS days" +%s)
aws s3api list-objects-v2 --bucket "$BUCKET" --query 'Contents[].{Key:Key,LastModified:LastModified}' --output json | \
  jq -r '.[] | "\(.Key)\t\(.LastModified)"' | while IFS=$'\t' read -r key mod; do
    ts=$(date -u -d "$mod" +%s)
    if (( ts < cutoff )); then
      aws s3api delete-object --bucket "$BUCKET" --key "$key"
      echo "Deleted $key (older than $DAYS days)"
    fi
  done