#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# gcp_deploy.sh - push image to GCR and update GKE deployment
IMAGE="$1"  # local built image tag
GCR_REPO=${GCR_REPO-}
K8S_DEPLOY=${K8S_DEPLOY-myapp}

if [[ -z "$IMAGE" ]]; then echo "Usage: $0 <image-tag>"; exit 1; fi

if [[ -n "$GCR_REPO" ]]; then
  docker tag "$IMAGE" "$GCR_REPO"
  docker push "$GCR_REPO"
  IMAGE="$GCR_REPO"
fi

if command -v kubectl >/dev/null; then
  kubectl set image deployment/${K8S_DEPLOY} ${K8S_DEPLOY}="${IMAGE}"
else
  echo "kubectl not found; pushed image: ${IMAGE}"
fi
