#!/bin/bash
# Example: Customize a VM image (install packages, run commands)

set -euo pipefail

IMAGE_DIR="${IMAGE_DIR:-./images}"
IMAGE_FILE="${1:-vm-image.qcow2}"
IMAGE="${IMAGE:-ghcr.io/stackopshq/libguestfs-tools:latest}"

echo "Customizing $IMAGE_FILE..."

podman run --rm \
  -v "$IMAGE_DIR:/workspace/images:Z" \
  "$IMAGE" \
  virt-customize -a "/workspace/images/$IMAGE_FILE" \
  --install nginx,curl \
  --run-command "systemctl enable nginx" \
  --root-password password:changeme

echo "Customization complete!"
