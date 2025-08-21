#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
APP_DIR=${1-}
BUILD_TOOL=${2-maven}   # maven|npm
IMAGE=${3-}
POST_DEPLOY_CMD=${4-}
[[ $APP_DIR && $IMAGE ]] || { echo "Usage: $0 <app_dir> <maven|npm> <image[:tag]> [post_deploy_cmd]"; exit 1; }

pushd "$APP_DIR" >/dev/null

git fetch --all --prune
 git reset --hard origin/"$(git rev-parse --abbrev-ref HEAD)"

case "$BUILD_TOOL" in
  maven) mvn -B -DskipTests clean package ;;
  npm) npm ci && npm run build ;;
  *) echo "Unknown build tool: $BUILD_TOOL"; exit 1 ;;
esac

HASH=$(git rev-parse --short HEAD)
STAMP=$(date +%Y%m%d_%H%M%S)
TAG="$IMAGE-$STAMP-$HASH"

docker build -t "$TAG" .
docker tag "$TAG" "$IMAGE"

docker login -u "$DOCKER_USER" -p "$DOCKER_PASS" 2>/dev/null || true

docker push "$TAG" || true
 docker push "$IMAGE" || true

popd >/dev/null

if [[ -n "$POST_DEPLOY_CMD" ]]; then
  bash -c "$POST_DEPLOY_CMD"
fi

echo "Deployed image: $TAG"