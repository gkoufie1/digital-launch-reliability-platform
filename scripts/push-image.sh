#!/usr/bin/env bash
# Build the app image and push it to ECR, tagged with the current git short SHA.
# Usage: scripts/push-image.sh [tag]     (requires AWS_PROFILE / credentials and Docker)
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree has uncommitted changes; commit first so the tag matches the code." >&2
  exit 1
fi

TAG="${1:-$(git rev-parse --short HEAD)}"
REPO_URL="$(terraform -chdir=infra/envs/dev output -raw ecr_repository_url)"
REGISTRY="${REPO_URL%%/*}"
REGION="$(echo "$REGISTRY" | cut -d. -f4)"

echo "Logging in to $REGISTRY"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

echo "Building $REPO_URL:$TAG"
docker build --platform linux/amd64 -t "$REPO_URL:$TAG" .

echo "Pushing $REPO_URL:$TAG"
docker push "$REPO_URL:$TAG"

echo
echo "Pushed. Deploy with:"
echo "  terraform -chdir=infra/envs/dev apply -var image_tag=$TAG"
