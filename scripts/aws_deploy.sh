#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# aws_deploy.sh - push docker image to ECR and update ECS service or EKS deployment
IMAGE="$1"  # full image tag (e.g. 123456.dkr.ecr.region.amazonaws.com/myapp:tag)
CLUSTER=${CLUSTER-}
SERVICE=${SERVICE-}
ECR_REPO=${ECR_REPO-}

if [[ -z "$IMAGE" ]]; then echo "Usage: $0 <image-tag>"; exit 1; fi

# If ECR repo provided, login and push
if [[ -n "${ECR_REPO}" ]]; then
  aws ecr get-login-password | docker login --username AWS --password-stdin "$(echo $ECR_REPO | cut -d/ -f1)"
  docker tag "$IMAGE" "${ECR_REPO}"
  docker push "${ECR_REPO}"
  IMAGE="${ECR_REPO}"
fi

# Deploy: if ECS vars set, update service; if kubectl present, patch deployment
if [[ -n "${CLUSTER}" && -n "${SERVICE}" ]]; then
  echo "Updating ECS service ${SERVICE} in cluster ${CLUSTER} to image ${IMAGE}"
  aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --force-new-deployment >/dev/null
elif command -v kubectl >/dev/null; then
  echo "Patching k8s deployment 'myapp' with image ${IMAGE}"
  kubectl set image deployment/myapp myapp="${IMAGE}"
else
  echo "No deployment target configured. Image available: ${IMAGE}"
fi
