#!/bin/bash
# Example: Inspect a VM image to get OS and application information

set -euo pipefail

IMAGE_DIR="${IMAGE_DIR:-./images}"
IMAGE_FILE="${1:-vm-image.qcow2}"
IMAGE="${IMAGE:-ghcr.io/stackopshq/libguestfs-tools:latest}"

echo "Inspecting $IMAGE_FILE..."

podman run --rm \
  -v "$IMAGE_DIR:/workspace/images:Z" \
  "$IMAGE" \
  virt-inspector -a "/workspace/images/$IMAGE_FILE"
