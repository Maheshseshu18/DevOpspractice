#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
[[ $(command -v kubectl) ]] || { echo "kubectl not found"; exit 1; }

mapfile -t NS < <(kubectl get ns -o jsonpath='{.items[*].metadata.name}')
for ns in "${NS[@]}"; do
  mapfile -t DEPLOY < <(kubectl -n "$ns" get deploy -o jsonpath='{.items[*].metadata.name}')
  for d in "${DEPLOY[@]}"; do
    desired=$(kubectl -n "$ns" get deploy "$d" -o jsonpath='{.status.replicas}')
    available=$(kubectl -n "$ns" get deploy "$d" -o jsonpath='{.status.availableReplicas}')
    desired=${desired:-0}; available=${available:-0}
    if (( available < desired )); then
      echo "[$ns/$d] Unavailable: $available/$desired. Restarting..."
      kubectl -n "$ns" rollout restart deploy "$d"
    fi
  done
 done