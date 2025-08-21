#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# azure_deploy.sh - push to ACR and update AKS or Web App
IMAGE="$1"
ACR_NAME=${ACR_NAME-}
AKS_NS=${AKS_NS-default}
AKS_DEPLOY=${AKS_DEPLOY-myapp}

if [[ -z "$IMAGE" ]]; then echo "Usage: $0 <image-tag>"; exit 1; fi

if [[ -n "$ACR_NAME" ]]; then
  ACR_LOGIN_SERVER=$(az acr show -n "$ACR_NAME" --query loginServer -o tsv)
  docker tag "$IMAGE" "${ACR_LOGIN_SERVER}/${IMAGE##*/}"
  docker push "${ACR_LOGIN_SERVER}/${IMAGE##*/}"
  IMAGE="${ACR_LOGIN_SERVER}/${IMAGE##*/}"
fi

if command -v kubectl >/dev/null; then
  kubectl -n "${AKS_NS}" set image deployment/${AKS_DEPLOY} ${AKS_DEPLOY}="${IMAGE}"
else
  echo "Image pushed: ${IMAGE}"
fi
