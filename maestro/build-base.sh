#!/bin/bash

# Build and push Swift SDK base image to GitHub Container Registry
# Usage: ./build-base.sh [github-username]

REGISTRY_USER=${1:-"lucasfeijo"}
IMAGE_NAME="swift-sdk-base"
TAG="6.1.2"
GHCR_IMAGE="ghcr.io/${REGISTRY_USER}/${IMAGE_NAME}:${TAG}"

echo "Building base image..."
docker build -f Dockerfile.base -t ${IMAGE_NAME}:${TAG} .

echo "Tagging for GitHub Container Registry..."
docker tag ${IMAGE_NAME}:${TAG} ${GHCR_IMAGE}

echo "Pushing to GitHub Container Registry..."
docker push ${GHCR_IMAGE}

echo "Base image pushed successfully!"
echo "Image available at: ${GHCR_IMAGE}" 